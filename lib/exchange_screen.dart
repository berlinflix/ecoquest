import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  List<dynamic> _myFriends = [];

  StreamSubscription<DocumentSnapshot>? _userSub;

  @override
  void initState() {
    super.initState();
    _listenToFriends();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  void _listenToFriends() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    _userSub = _firestore.collection('users').doc(uid).snapshots().listen(
      (doc) {
        if (!doc.exists) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        final data = doc.data();
        if (data != null) {
          final List<dynamic> friendIds = data['friends'] ?? [];
          if (mounted) {
            setState(() {
              _myFriends = friendIds;
              _isLoading = false;
            });
          }
        }
      },
      onError: (e) {
        debugPrint('Error listening to friends: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _showPostRequestModal() {
    final itemController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FBFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What do you need?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0A1931),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: itemController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Rubber Gloves, 5m Ladder',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.blueGrey.shade100),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.blueGrey.shade100),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _postRequest(itemController.text, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF30E3CA),
                      foregroundColor: const Color(0xFF0A1931),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    child: Text(
                      'POST REQUEST',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _postRequest(String itemName, BuildContext sheetContext) async {
    if (itemName.trim().isEmpty) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    Navigator.pop(sheetContext);

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();
      final name = '${userData?['firstName'] ?? 'User'} ${userData?['lastName'] ?? ''}'.trim();
      final photoUrl = userData?['profileImageUrl'];

      await _firestore.collection('exchange_requests').add({
        'itemName': itemName.trim(),
        'requesterId': uid,
        'requesterName': name,
        'requesterPhotoUrl': photoUrl,
        'status': 'open',
        'offers': [], // new array to track who offered help
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting request: $e')),
        );
      }
    }
  }

  Future<void> _deleteRequest(String requestId, String itemName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // First, get the request to verify ownership or admin rights before deleting
      final doc = await _firestore.collection('exchange_requests').doc(requestId).get();
      if (!doc.exists) return;

      // In a real app we'd want server-side security rules for this, but for now we'll allow 
      // the user to delete it either if they created it, or (as requested) we're adding the
      // delete button generally on friends' requests too.
      await _firestore.collection('exchange_requests').doc(requestId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request for $itemName deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting request: $e')),
        );
      }
    }
  }

  Future<void> _offerHelp(String requestId, String requesterId, String itemName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid == requesterId) return;

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();
      final helperName = '${userData?['firstName'] ?? 'A friend'} ${userData?['lastName'] ?? ''}'.trim();

      // Ensure we don't accidentally offer twice immediately
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Awesome! We let them know you can help with the $itemName.')),
      );

      final batch = _firestore.batch();
      final requestRef = _firestore.collection('exchange_requests').doc(requestId);
      
      batch.update(requestRef, {
        'offers': FieldValue.arrayUnion([uid])
      });

      // Send a notification!
      final notificationRef = _firestore.collection('users').doc(requesterId).collection('notifications').doc();
      batch.set(notificationRef, {
        'type': 'exchange_offer',
        'fromUserId': uid,
        'fromUserName': helperName,
        'requestId': requestId,
        'itemName': itemName,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error offering help: $e');
    }
  }

  void _showOfferBottomSheet(List<dynamic> offers) async {
    if (offers.isEmpty) return;
    
    // For demo purposes, we will just show the first person who offered help
    final helperId = offers.first;
    
    Map<String, dynamic>? helperData;
    try {
       final doc = await _firestore.collection('users').doc(helperId).get();
       helperData = doc.data();
    } catch (e) {
       debugPrint('Error loading helper data');
       return;
    }

    if (helperData == null || !mounted) return;

    final name = '${helperData['firstName'] ?? 'User'} ${helperData['lastName'] ?? ''}'.trim();
    final photoUrl = helperData['profileImageUrl'];
    final email = helperData['email'] ?? 'No email provided';
    final phone = helperData['mobile'] ?? 'No phone provided';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
               BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 40, offset: const Offset(0, -10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    Text(
                      '${offers.length} Friend can help!',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A2B48)),
                    ),
                    Text(
                      'Found a match in your circle',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 24),
                    
                    // Profile Image
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFF30D5C8).withValues(alpha: 0.1), width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photoUrl != null 
                        ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                        : Container(color: Colors.blueGrey.shade50, child: const Icon(Icons.person, size: 48, color: Colors.blueGrey)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A2B48)),
                    ),
                    Text(
                      'Active Member',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF30D5C8)),
                    ),
                    const SizedBox(height: 32),

                    // Contact Cards
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                           Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                              child: const Icon(Icons.mail_outline, color: Color(0xFF30D5C8)),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text('EMAIL ADDRESS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.5)),
                                 Text(email, style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: const Color(0xFF1A2B48))),
                               ],
                             ),
                           )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                           Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                              child: const Icon(Icons.phone_outlined, color: Color(0xFF30D5C8)),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text('PHONE NUMBER', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.5)),
                                 Text(phone, style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: const Color(0xFF1A2B48))),
                               ],
                             ),
                           )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                           child: ElevatedButton.icon(
                              onPressed: () { 
                                 launchUrl(Uri.parse('tel:$phone'));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF30D5C8),
                                foregroundColor: const Color(0xFF1A2B48),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 8,
                                shadowColor: const Color(0xFF30D5C8).withValues(alpha: 0.3),
                              ),
                              icon: const Icon(Icons.call, size: 20),
                              label: Text('CALL', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                           ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                           child: OutlinedButton.icon(
                              onPressed: () { 
                                 launchUrl(Uri.parse('mailto:$email'));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1A2B48),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                side: const BorderSide(color: Color(0xFF1A2B48), width: 2),
                              ),
                              icon: const Icon(Icons.mail, size: 20),
                              label: Text('EMAIL', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                           ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uid = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFF30D5C8).withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.eco_outlined, color: Color(0xFF30D5C8)),
                  ),
                  Text(
                    'Eco Exchange',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A2B48),
                    ),
                  ),
                  
                  // Notifications Bell with Badge
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').doc(uid).collection('notifications')
                        .where('read', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                      return Stack(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                            child: const Icon(Icons.notifications_none_outlined, color: Colors.grey),
                          ),
                          if (hasUnread)
                             Positioned(
                               top: 8, right: 8,
                               child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                             )
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Hero Gradient Banner
                  Container(
                    height: 192,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 25, offset: const Offset(0, 10))],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, const Color(0xFF1A2B48).withValues(alpha: 0.6)],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 24, left: 24, right: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COMMUNITY SHARING',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF30D5C8),
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lend & Borrow',
                                style: GoogleFonts.outfit(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Post Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _showPostRequestModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF30D5C8),
                        foregroundColor: const Color(0xFF1A2B48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 8,
                        shadowColor: const Color(0xFF30D5C8).withValues(alpha: 0.2),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: Text(
                        'POST REQUEST',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Your Requests
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 16),
                    child: Text(
                      'YOUR REQUESTS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  _buildMyRequestsFeed(uid),

                  const SizedBox(height: 24),

                  // Active Requests Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 16),
                    child: Text(
                      'ACTIVE REQUESTS FROM FRIENDS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  // Friend Feed
                  _buildFriendsFeed(uid),
                  
                  const SizedBox(height: 120), // Bottom Nav padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequestsFeed(String currentUid) {
     return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('exchange_requests')
           .where('requesterId', isEqualTo: currentUid)
           .snapshots(),
        builder: (context, snapshot) {
           if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red)));
           }
           
           if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
           }

           final allDocs = snapshot.data!.docs.where((doc) {
             final data = doc.data() as Map<String, dynamic>;
             return data['status'] == 'open';
           }).toList();

          if (allDocs.isEmpty) {
              return Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(24),
                   border: Border.all(color: const Color(0xFF30D5C8).withValues(alpha: 0.2)),
                 ),
                 child: Center(
                    child: Text('You have no active requests.', style: GoogleFonts.outfit(color: Colors.grey)),
                 ),
              );
           }

           allDocs.sort((a, b) {
             final aData = a.data() as Map<String, dynamic>;
             final bData = b.data() as Map<String, dynamic>;
             final aTime = aData['timestamp'] as Timestamp?;
             final bTime = bData['timestamp'] as Timestamp?;
             if (aTime == null && bTime == null) return 0;
             if (aTime == null) return 1; 
             if (bTime == null) return -1;
             return bTime.compareTo(aTime);
           });

           return Column(
              children: allDocs.map((doc) {
                 final data = doc.data() as Map<String, dynamic>;
                 final itemName = data['itemName'] ?? 'Unknown Item';
                 final List<dynamic> offers = data['offers'] ?? [];
                 final hasOffers = offers.isNotEmpty;

                 return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(24),
                       border: Border.all(color: const Color(0xFF30D5C8).withValues(alpha: 0.2)),
                       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 25, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                       children: [
                          Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                Container(
                                   width: 48, height: 48,
                                   decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                                   child: const Icon(Icons.person_outline, color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                 Expanded(
                                    child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                          Text('You are looking for:', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
                                          Text(itemName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A2B48))),
                                       ],
                                    ),
                                 ),
                                 IconButton(
                                   icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                   onPressed: () => _deleteRequest(doc.id, itemName),
                                 ),
                                 if (hasOffers)
                                   Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                         color: const Color(0xFF30D5C8).withValues(alpha: 0.1),
                                         border: Border.all(color: const Color(0xFF30D5C8).withValues(alpha: 0.2)),
                                         borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                         mainAxisSize: MainAxisSize.min,
                                         children: [
                                            const Icon(Icons.celebration_outlined, color: Color(0xFF30D5C8), size: 14),
                                            const SizedBox(width: 4),
                                            Text('${offers.length} Friend can help!', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF30D5C8))),
                                         ],
                                      ),
                                   ),
                             ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                             width: double.infinity,
                             height: 48,
                             child: OutlinedButton.icon(
                                onPressed: hasOffers ? () => _showOfferBottomSheet(offers) : null,
                                style: OutlinedButton.styleFrom(
                                   foregroundColor: const Color(0xFF30D5C8),
                                   side: BorderSide(color: const Color(0xFF30D5C8).withValues(alpha: hasOffers ? 1.0 : 0.2)),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                label: Text('View Offers', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                             ),
                          )
                       ],
                    ),
                 );
              }).toList(),
           );
        },
     );
  }

  Widget _buildFriendsFeed(String currentUid) {
    if (_myFriends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No friends yet! Add some to borrow and lend items.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.blueGrey),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('exchange_requests')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
           return Text('Error loading feed: \n${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
        }

        final allDocs = snapshot.data!.docs.toList();
        
        // Sort locally by timestamp descending
        allDocs.sort((a, b) {
           final aData = a.data() as Map<String, dynamic>;
           final bData = b.data() as Map<String, dynamic>;
           final aTime = aData['timestamp'] as Timestamp?;
           final bTime = bData['timestamp'] as Timestamp?;
           if (aTime == null && bTime == null) return 0;
           if (aTime == null) return 1; 
           if (bTime == null) return -1;
           return bTime.compareTo(aTime);
        });

        final friendDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final reqId = data['requesterId'] as String?;
          // Ensure it's in our friend network, but not our own requests!
          return reqId != null && _myFriends.contains(reqId) && reqId != currentUid;
        }).toList();

        if (friendDocs.isEmpty) {
           return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No active requests from your network right now.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            );
        }

        return Column(
          children: friendDocs.map((doc) => _buildRequestCard(doc, currentUid)).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(DocumentSnapshot doc, String currentUid) {
    final docId = doc.id;
    final data = doc.data() as Map<String, dynamic>;
    final itemName = data['itemName'] ?? 'Unknown Item';
    final name = data['requesterName'] ?? 'Someone';
    final requesterId = data['requesterId'];
    final photoUrl = data['requesterPhotoUrl'];
    
    final List<dynamic> offers = data['offers'] ?? [];
    final hasAlreadyOffered = offers.contains(currentUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoUrl != null 
                  ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                  : const Icon(Icons.person_outline, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name is looking for:',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      itemName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A2B48),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteRequest(docId, itemName),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: hasAlreadyOffered ? null : () => _offerHelp(docId, requesterId, itemName),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF30D5C8),
                side: BorderSide(color: const Color(0xFF30D5C8).withValues(alpha: 0.3)),
                backgroundColor: hasAlreadyOffered ? Colors.grey.shade50 : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(hasAlreadyOffered ? Icons.check : Icons.volunteer_activism, size: 18),
              label: Text(
                hasAlreadyOffered ? 'Offered' : 'I can help!',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
