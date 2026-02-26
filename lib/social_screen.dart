import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_service.dart';
import 'level_utils.dart';
import 'friend_profile_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final AuthService _authService = AuthService();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  void _showAddFriendScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return const AddFriendScreen();
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUid == null) {
      return const Center(child: Text("Please log in to view the leaderboard."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const Center(child: Text("Profile data not found."));

        // Current user stats
        final String currentFirstName = userData['firstName'] ?? 'Player';
        final String currentLastName = userData['lastName'] ?? '';
        final int currentExp = userData['exp'] ?? 0;
        final int currentLevel = LevelUtils.calculateLevel(currentExp);
        
        // Get friends array
        final List<dynamic> rawFriends = userData['friends'] ?? [];
        final List<String> friendUids = rawFriends.cast<String>();

        // Build a list of UIDs to fetch (Friends + Current User)
        final List<String> leaderboardUids = [...friendUids, _currentUid!];

        return Stack(
          children: [
            // Pixel Beach Background
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC50zq7WZyi8ZcICZxZOCUO8jw_SH5-RoeCozACtdnAt9qtnUkUCJANPTFlUbCNOWzTC7lK_NPWs5_Iqyjhbk0GI2iKizvqsG1N6DRTBJwWYq57NOVNRWLqxUJv0WnsR1s-tAqa1maTwlU5HCnmggWPpNLORjZoJBr2--3sSe1px9v-FkVX2_kDHhtIXOulV8ZGNyRBASolAXGgS7-uHZ2twDtYPNhgVBAakR-SA854EWqcwHG4ire4vbQH5U504eLtpYjrBwNC6XU',
                fit: BoxFit.cover,
              ),
            ),
            
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.0), // Removing the white background to let the pixel art bleed consistently
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Balance the icon
                    const Text(
                      'LEADERBOARD',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A192F), // navy-deep
                        letterSpacing: -0.5,
                      ),
                    ),
                    _buildNotificationIcon(_currentUid),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 60, // Below header
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    // User Highlight Card (You)
                    _buildUserHighlightCard(currentFirstName, currentLastName, currentLevel, currentExp),
                    const SizedBox(height: 24),

                    // Add Friend Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _showAddFriendScreen,
                        icon: const Icon(Icons.person_add, size: 28),
                        label: const Text('FIND FRIENDS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077b6), // ocean-blue
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          elevation: 8,
                          shadowColor: const Color(0xFF0077b6).withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Leaderboard Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('FRIEND SQUAD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0A192F).withOpacity(0.7), letterSpacing: 1.5)),
                        Text('Top Users', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0A192F).withOpacity(0.5))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Top Friends Stream
                    _buildLeaderboardList(leaderboardUids),
                    
                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildUserHighlightCard(String firstName, String lastName, int level, int exp) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF25F4AF).withOpacity(0.2), // primary
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Center(child: Icon(Icons.scuba_diving, size: 48, color: Color(0xFF0A192F))),
              ),
              Positioned(
                bottom: -8, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A192F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$firstName $lastName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A192F), height: 1.0)),
                const SizedBox(height: 4),
                Text('LEVEL $level EXPLORER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0A192F).withOpacity(0.6), letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), // Neutral track
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double progress = LevelUtils.calculateProgress(exp).clamp(0.0, 1.0);
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(color: const Color(0xFF25F4AF), borderRadius: BorderRadius.circular(4)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$exp EXP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0A192F))),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<String> uidsToFetch) {
    if (uidsToFetch.isEmpty) return const SizedBox.shrink();

    // Firebase max 'whereIn' array size is 10. If a user has > 10 friends, 
    // we would need to chunk this or do clientside sorting on a larger query.
    // For this MVP, we limit the query to the first 10 for simplicity.
    List<String> safeUids = uidsToFetch.take(10).toList();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: safeUids)
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Extract docs and sort locally by exp descending (Cloud firestore doesn't allow orderby on fields not in the where filter easily without composites)
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          int expA = (a.data() as Map<String, dynamic>)['exp'] ?? 0;
          int expB = (b.data() as Map<String, dynamic>)['exp'] ?? 0;
          return expB.compareTo(expA); // Descending
        });

        return Column(
          children: List.generate(docs.length, (index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            
            // Map colors exactly like the HTML (1st Orange, 2nd Blue, 3rd Mint, rest Yellow)
            Color iconBgColor;
            IconData iconToUse;
            if (index == 0) { iconBgColor = Colors.orange.shade100; iconToUse = Icons.surfing; }
            else if (index == 1) { iconBgColor = Colors.blue.shade100; iconToUse = Icons.hiking; }
            else if (index == 2) { iconBgColor = const Color(0xFF25F4AF).withOpacity(0.1); iconToUse = Icons.sailing; } 
            else { iconBgColor = Colors.yellow.shade100; iconToUse = Icons.kayaking; }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildFriendTile(
                isCurrentUser: uid == _currentUid,
                rank: index + 1,
                firstName: data['firstName'] ?? 'Player',
                lastName: data['lastName'] ?? '',
                exp: data['exp'] ?? 0,
                bgColor: iconBgColor,
                icon: iconToUse,
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(userId: uid, userData: data)));
                }
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFriendTile({required bool isCurrentUser, required int rank, required String firstName, required String lastName, required int exp, required Color bgColor, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7), // frosted-glass
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0A192F).withOpacity(rank <= 3 ? 1.0 : 0.4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Icon Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, color: const Color(0xFF0A192F)),
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                         child: Text('$firstName $lastName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0A192F)), overflow: TextOverflow.ellipsis),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF0A192F), borderRadius: BorderRadius.circular(8)),
                          child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                  Text('${exp} EXP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0A192F).withOpacity(0.5), letterSpacing: 1.0)),
                ],
              ),
            ),

            // Action Indicator
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0A192F).withOpacity(0.05)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Icon(Icons.front_hand, size: 20, color: Color(0xFF0A192F)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String? uid) {
    if (uid == null) {
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
        child: const Icon(Icons.park, color: Color(0xFF0A192F), size: 20),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        bool hasPending = false;
        List<dynamic> pendingRequests = [];
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            pendingRequests = data['pendingRequests'] ?? [];
            hasPending = pendingRequests.isNotEmpty;
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque, // Increase touch area
          onTap: () {
            _showRequestsModal(context, pendingRequests, uid);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Padding to increase touch area
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.park, color: Color(0xFF0A192F), size: 20),
                ),
                if (hasPending)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRequestsModal(BuildContext context, List<dynamic> pendingUidList, String currentUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F8F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Friend Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A192F))),
              const SizedBox(height: 16),
              Expanded(
                child: pendingUidList.isEmpty
                  ? const Center(child: Text("No new notifications!", style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)))
                  : ListView.builder(
                  itemCount: pendingUidList.length,
                  itemBuilder: (context, index) {
                    final requesterId = pendingUidList[index] as String;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(requesterId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator());
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox.shrink();

                        final name = '${data['firstName']} ${data['lastName']}';
                        final username = '@${data['username']}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFF25F4AF).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.person, color: Color(0xFF0A192F)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A192F))),
                                    Text(username, style: TextStyle(fontSize: 12, color: const Color(0xFF0A192F).withOpacity(0.6))),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () {
                                  AuthService().acceptRequest(currentUid, requesterId);
                                  Navigator.pop(context);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  AuthService().rejectRequest(currentUid, requesterId);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  final AuthService _authService = AuthService();
  
  String _searchQuery = '';
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) async {
    setState(() {
      _searchQuery = value.trim();
      _isSearching = true;
    });

    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      // Very basic prefix search in Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .limit(10)
          .get();

      setState(() {
        _searchResults = snapshot.docs.where((doc) => doc.id != _currentUid).toList();
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _sendRequest(String targetUsername) async {
    final currentUid = _currentUid;
    if (currentUid == null) return;
    try {
      await _authService.sendFriendRequest(currentUid, targetUsername);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request sent to @$targetUsername!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0A192F)),
        title: const Text('Find Friends', style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Search by Handle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0A192F), letterSpacing: 1.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: '@username',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0077b6)),
                    filled: true,
                    fillColor: const Color(0xFFF5F8F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sync Contacts Button
                OutlinedButton.icon(
                  onPressed: _syncContacts,
                  icon: const Icon(Icons.contacts, color: Color(0xFF0077b6)),
                  label: const Text('SYNC CONTACTS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A192F), letterSpacing: 1.0)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: const Color(0xFF0A192F).withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchQuery.isEmpty && _searchResults.isEmpty
                    ? Center(child: Text("Search for an Eco Quest handle\nor sync your contacts.", textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF0A192F).withOpacity(0.5), fontWeight: FontWeight.bold)))
                    : StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(_currentUid).snapshots(),
                        builder: (context, currentUserSnapshot) {
                          List<dynamic> myFriends = [];
                          List<dynamic> mySent = [];
                          List<dynamic> myPending = [];
                          
                          if (currentUserSnapshot.hasData && currentUserSnapshot.data!.exists) {
                            final myData = currentUserSnapshot.data!.data() as Map<String, dynamic>?;
                            if (myData != null) {
                              myFriends = myData['friends'] ?? [];
                              mySent = myData['sentRequests'] ?? [];
                              myPending = myData['pendingRequests'] ?? [];
                            }
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final uid = _searchResults[index].id;
                              final data = _searchResults[index].data() as Map<String, dynamic>;
                              final name = '${data['firstName']} ${data['lastName']}';
                              final username = '${data['username']}';
                              final exp = data['exp'] ?? 0;

                              bool isFriend = myFriends.contains(uid);
                              bool isPending = mySent.contains(uid) || myPending.contains(uid);

                              Color iconBgColor;
                              IconData iconToUse;
                              int colorIdx = exp % 4;
                              if (colorIdx == 0) { iconBgColor = Colors.orange.shade100; iconToUse = Icons.surfing; }
                              else if (colorIdx == 1) { iconBgColor = Colors.blue.shade100; iconToUse = Icons.hiking; }
                              else if (colorIdx == 2) { iconBgColor = const Color(0xFF25F4AF).withOpacity(0.1); iconToUse = Icons.sailing; } 
                              else { iconBgColor = Colors.yellow.shade100; iconToUse = Icons.kayaking; }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(userId: uid, userData: data)));
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                                        child: Icon(iconToUse, color: const Color(0xFF0A192F)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A192F), fontSize: 16)),
                                            Text('@$username • $exp EXP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0A192F).withOpacity(0.5))),
                                          ],
                                        ),
                                      ),
                                      if (isFriend)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: const Color(0xFF0A192F).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                          child: const Text('FRIENDS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A192F), fontSize: 12)),
                                        )
                                      else if (isPending)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                          child: const Text('PENDING', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.deepOrange, fontSize: 12)),
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: () => _sendRequest(username),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF25F4AF),
                                            foregroundColor: const Color(0xFF0A192F),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w900)),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncContacts() async {
    setState(() => _isSearching = true);

    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
        
        List<String> normalizedContacts = [];
        for (var contact in contacts) {
          for (var phone in contact.phones) {
             // Remove all non-digits
             String digitsOnly = phone.number.replaceAll(RegExp(r'[^\d]'), '');
             // Store the last 10 digits to ignore country codes for matching
             if (digitsOnly.length >= 10) {
                 normalizedContacts.add(digitsOnly.substring(digitsOnly.length - 10));
             } else if (digitsOnly.isNotEmpty) {
                 normalizedContacts.add(digitsOnly);
             }
          }
        }

        if (normalizedContacts.isEmpty) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid phone numbers found in contacts.')));
          setState(() => _isSearching = false);
          return;
        }

        // Fetch all users to do robust local matching (ideal for MVP/Hackathon)
        final allUsersSnapshot = await FirebaseFirestore.instance.collection('users').get();
        List<DocumentSnapshot> matches = [];

        for (var doc in allUsersSnapshot.docs) {
           if (doc.id == _currentUid) continue; // Skip current user
           final userData = doc.data();
           final userMobile = userData['mobile'] as String?;
           
           if (userMobile != null && userMobile.isNotEmpty) {
               // Extract last 10 digits of user's registered mobile
               String userDigits = userMobile.replaceAll(RegExp(r'[^\d]'), '');
               String userLast10 = userDigits.length >= 10 ? userDigits.substring(userDigits.length - 10) : userDigits;
               
               if (userLast10.length > 5 && normalizedContacts.contains(userLast10)) {
                   matches.add(doc);
               }
           }
        }

        setState(() {
          _searchResults = matches;
          _isSearching = false;
        });

        if (matches.isEmpty && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('None of your contacts are currently playing Eco Quest.')));
        }

      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission to read contacts denied.')));
        setState(() => _isSearching = false);
      }
    } catch (e) {
      debugPrint('Error syncing contacts: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sync contacts: $e')));
      setState(() => _isSearching = false);
    }
  }
}
