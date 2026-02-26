import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'location_picker_dialog.dart';

class CreateSquadScreen extends StatefulWidget {
  const CreateSquadScreen({super.key});

  @override
  State<CreateSquadScreen> createState() => _CreateSquadScreenState();
}

class _CreateSquadScreenState extends State<CreateSquadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _squadNameController = TextEditingController();
  final _missionTitleController = TextEditingController();
  final _missionDescController = TextEditingController();
  
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;

  // Selected Location (Default to roughly San Francisco)
  LatLng _selectedLocation = const LatLng(37.7749, -122.4194);
  List<String> _selectedFriendUids = [];
  
  List<Map<String, dynamic>> _myFriends = [];
  bool _isLoadingFriends = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    if (_currentUid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
      final data = doc.data();
      if (data != null) {
        final List<dynamic> friendIds = data['friends'] ?? [];
        if (friendIds.isNotEmpty) {
           final friendsSnap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: friendIds.take(10).toList())
              .get();
              
           setState(() {
             _myFriends = friendsSnap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
             _isLoadingFriends = false;
           });
        } else {
           _fetchFallbackUsers();
        }
      } else {
         _fetchFallbackUsers();
      }
    } catch (e) {
      debugPrint("Error fetching friends: $e");
      _fetchFallbackUsers();
    }
  }

  Future<void> _fetchFallbackUsers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, isNotEqualTo: _currentUid).limit(10).get();
      setState(() {
         _myFriends = snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
         _isLoadingFriends = false;
      });
    } catch (e) {
      debugPrint("Fallback fetch error: $e");
      setState(() => _isLoadingFriends = false);
    }
  }

  void _createSquad() async {
    if (!_formKey.currentState!.validate() || _currentUid == null) return;
    if (_selectedFriendUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one friend to join your squad!')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final members = [_currentUid!, ..._selectedFriendUids];
      await FirebaseFirestore.instance.collection('squads').add({
        'name': _squadNameController.text.trim(),
        'creatorId': _currentUid,
        'memberIds': members,
        'missionTitle': _missionTitleController.text.trim(),
        'missionDescription': _missionDescController.text.trim(),
        'missionLat': _selectedLocation.latitude,
        'missionLng': _selectedLocation.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        Navigator.pop(context); // Go back after creation
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Squad Created Successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
        setState(() => _isLoading = false);
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
        title: Text(
          'Create Squad',
          style: GoogleFonts.outfit(color: const Color(0xFF0A192F), fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionHeader('SQUAD IDENTITY'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _squadNameController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  decoration: _inputDecoration('Squad Name'),
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader('CURRENT MISSION'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _missionTitleController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  decoration: _inputDecoration('Mission Title'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _missionDescController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  maxLines: 3,
                  decoration: _inputDecoration('Mission Description'),
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader('INVITE FRIENDS'),
                const SizedBox(height: 12),
                _buildFriendSelector(),
                
                const SizedBox(height: 32),
                _buildSectionHeader('MISSION LOCATION PIN'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                       Container(
                         width: 48, height: 48,
                         decoration: BoxDecoration(color: const Color(0xFFFDE68A), borderRadius: BorderRadius.circular(16)),
                         child: const Icon(Icons.location_on, color: Color(0xFFD97706)),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Coordinates Set', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                             Text('${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                           ],
                         ),
                       ),
                       TextButton(
                         onPressed: () async {
                           final LatLng? result = await showDialog<LatLng>(
                             context: context,
                             barrierDismissible: false,
                             builder: (_) => LocationPickerDialog(initialLocation: _selectedLocation),
                           );
                           if (result != null) {
                             setState(() => _selectedLocation = result);
                           }
                         },
                         style: TextButton.styleFrom(backgroundColor: const Color(0xFFE2E8F0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                         child: Text('EDIT PIN', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                       )
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _createSquad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: Text('CREATE SQUAD', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6), letterSpacing: 1.5),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(20),
    );
  }

  Widget _buildFriendSelector() {
    if (_isLoadingFriends) return const Center(child: CircularProgressIndicator());
    if (_myFriends.isEmpty) return const Text('Add some friends on the Social screen first!');

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _myFriends.length,
        itemBuilder: (context, index) {
          final friend = _myFriends[index];
          final uid = friend['uid'];
          final isSelected = _selectedFriendUids.contains(uid);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedFriendUids.remove(uid);
                } else {
                  _selectedFriendUids.add(uid);
                }
              });
            },
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF2DD4BF) : Colors.transparent, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFF0A192F).withOpacity(0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: Color(0xFF0A192F)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    friend['firstName'] ?? 'Player',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
