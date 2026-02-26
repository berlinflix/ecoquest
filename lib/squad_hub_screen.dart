import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_squad_screen.dart';

class SquadHubScreen extends StatefulWidget {
  const SquadHubScreen({super.key});

  @override
  State<SquadHubScreen> createState() => _SquadHubScreenState();
}

class _SquadHubScreenState extends State<SquadHubScreen> {
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  String? _expandedSquadId; // Used for the accordion style UI

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri url = Uri.parse(googleMapsUrl);
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open map app. Ensure a browser or Maps is installed.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error launching maps: $e')));
    }
  }

  void _deleteSquad(String squadId, String squadName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.waves, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'Dissolve Squad?',
                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.blueGrey, height: 1.5),
                  children: [
                    const TextSpan(text: 'Are you sure you want to permanently delete '),
                    TextSpan(text: squadName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const TextSpan(text: ' and its mission? This action cannot be undone.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DD3FC).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF1E3A8A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: Text('KEEP SQUAD', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await FirebaseFirestore.instance.collection('squads').doc(squadId).delete();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$squadName deleted.')));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.red.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: Text('DELETE', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          'Squad Hub',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSquadScreen())),
              icon: const Icon(Icons.add, size: 16),
              label: Text('CREATE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 4,
              ),
            ),
          )
        ],
      ),
      body: _currentUid == null
          ? const Center(child: Text("Please login to see squads!"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('squads')
                  .where('memberIds', arrayContains: _currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                 }
                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                   return Center(
                     child: Text(
                       "No Active Squads\\nCreate one or ask a friend!",
                       textAlign: TextAlign.center,
                       style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A).withOpacity(0.5), fontWeight: FontWeight.bold),
                     ),
                   );
                 }

                 final squads = snapshot.data!.docs;
                 squads.sort((a, b) {
                   final timeA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                   final timeB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                   if (timeA == null && timeB == null) return 0;
                   if (timeA == null) return 1;
                   if (timeB == null) return -1;
                   return timeB.compareTo(timeA); // descending
                 });

                 return ListView.builder(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                   itemCount: squads.length,
                   itemBuilder: (context, index) {
                     final sq = squads[index].data() as Map<String, dynamic>;
                     final id = squads[index].id;
                     return _buildSquadCard(id, sq, index);
                   },
                 );
              },
            ),
    );
  }

  Widget _buildSquadCard(String id, Map<String, dynamic> data, int index) {
    bool isExpanded = _expandedSquadId == id;
    final List<dynamic> memberIds = data['memberIds'] ?? [];
    
    // Aesthetic cycle matching the tailwind design
    Color iconBgColor; Color iconColor; IconData icon;
    if (index % 3 == 0) { iconBgColor = const Color(0xFF0F172A); iconColor = Colors.white; icon = Icons.waves; }
    else if (index % 3 == 1) { iconBgColor = Colors.teal.withOpacity(0.1); iconColor = Colors.teal; icon = Icons.eco; }
    else { iconBgColor = Colors.blue.withOpacity(0.1); iconColor = Colors.blue; icon = Icons.water_drop; }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isExpanded ? Colors.white : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _expandedSquadId = isExpanded ? null : id),
            borderRadius: BorderRadius.circular(40),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(16)),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Squad',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          '${memberIds.length} Members Online',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.blueGrey.shade300),
                  if (data['creatorId'] == _currentUid)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                         // Prevent expand toggle when clicking delete
                         _deleteSquad(id, data['name'] ?? 'Squad');
                      },
                    )
                ],
              ),
            ),
          ),
          
          // Expanded Content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blueGrey.shade50),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text('CURRENT MISSION', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue.shade600, letterSpacing: 1.5)),
                               const SizedBox(height: 4),
                               Text(data['missionTitle'] ?? 'Pending', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), fontSize: 16)),
                             ],
                           ),
                         ),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(32),
                             border: Border.all(color: Colors.blueGrey.shade50),
                             boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               _buildMiniAvatarStack(memberIds.take(3).toList(), memberIds.length),
                             ],
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),
                     
                     // Interactive Map Container
                     if (data['missionLat'] != null && data['missionLng'] != null)
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blueGrey.shade50),
                          ),
                          child: Stack(
                            children: [
                               AbsorbPointer(
                                 child: FlutterMap(
                                   options: MapOptions(
                                     initialCenter: LatLng(data['missionLat'], data['missionLng']),
                                     initialZoom: 12.0,
                                   ),
                                   children: [
                                     TileLayer(
                                       urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                       userAgentPackageName: 'com.example.ecoquest',
                                     ),
                                     MarkerLayer(
                                       markers: [
                                         Marker(
                                           point: LatLng(data['missionLat'], data['missionLng']),
                                           width: 60, height: 60,
                                           child: Container(
                                             decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF32D4BC), width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                                             child: const Center(child: Icon(Icons.park, color: Color(0xFF32D4BC), size: 28)),
                                           ),
                                         )
                                       ],
                                     )
                                   ],
                                 ),
                               ),
                               Container(color: Colors.white.withValues(alpha: 0.1)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _openGoogleMaps(data['missionLat'], data['missionLng']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF32D4BC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: const Color(0xFF32D4BC).withValues(alpha: 0.3),
                          ),
                          child: Text('OPEN MISSION MAP', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                        ),
                      )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildMiniAvatarStack(List<dynamic> users, int total) {
    // Creating overlapping circles with staggered right margin purely visual
    return SizedBox(
      width: (28.0 * users.length) + (total > 3 ? 28.0 : 0) - (8.0 * (users.length - 1)),
      height: 28,
      child: Stack(
        children: List.generate(users.length + (total > 3 ? 1 : 0), (index) {
          if (index == users.length) {
            return Positioned(
              left: index * 20.0,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: Colors.blueGrey.shade100, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: Center(child: Text('+\${total - 3}', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600))),
              ),
            );
          }
          return Positioned(
            left: index * 20.0,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.person, size: 16, color: Color(0xFF0F172A)),
            ),
          );
        }),
      ),
    );
  }
}
