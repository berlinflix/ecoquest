import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'quest_screen.dart';
import 'quest_state.dart';
import 'social_screen.dart';
import 'map_screen.dart';
import 'squad_hub_screen.dart';
import 'exchange_screen.dart';
import 'dart:math';
const Color primaryMint = Color(0xFF25F4AF);
const Color backgroundLight = Color(0xFFF5F8F7);
const Color navyDeep = Color(0xFF0A192F);
const Color shadowMint = Color(0xFF1BA67A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                // 0: Home Feed
                Column(
                  children: [
                    _buildTopHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildHeroSection(),
                            _buildActionSection(context),
                            _buildHeatmapSection(),
                            const SizedBox(height: 100), // Padding for bottom nav
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // 1: Exchange Hub
                const ExchangeScreen(),
                // 2: Map (Placeholder)
                const Center(child: Text("Global Map Coming Soon")),
                // 3: Social Leaderboard
                const SocialScreen(),
              ],
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundLight.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: primaryMint.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryMint.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: primaryMint, width: 2),
            ),
            child: const Icon(Icons.eco, color: navyDeep, size: 20),
          ),
          const Text(
            'Eco Quest',
            style: TextStyle(
              color: navyDeep,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: primaryMint.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.park, color: navyDeep, size: 20),
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
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _showRequestsModal(context, pendingRequests, uid);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryMint.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.park, color: navyDeep, size: 20),
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
            color: backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Friend Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navyDeep)),
              const SizedBox(height: 16),
              Expanded(
                child: pendingUidList.isEmpty
                    ? Center(
                        child: Text(
                          'No new notifications!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: navyDeep.withOpacity(0.5),
                          ),
                        ),
                      )
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
                                decoration: BoxDecoration(color: primaryMint.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.person, color: navyDeep),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: navyDeep)),
                                    Text(username, style: TextStyle(fontSize: 12, color: navyDeep.withOpacity(0.6))),
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

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          decoration: BoxDecoration(
            color: primaryMint.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC50zq7WZyi8ZcICZxZOCUO8jw_SH5-RoeCozACtdnAt9qtnUkUCJANPTFlUbCNOWzTC7lK_NPWs5_Iqyjhbk0GI2iKizvqsG1N6DRTBJwWYq57NOVNRWLqxUJv0WnsR1s-tAqa1maTwlU5HCnmggWPpNLORjZoJBr2--3sSe1px9v-FkVX2_kDHhtIXOulV8ZGNyRBASolAXGgS7-uHZ2twDtYPNhgVBAakR-SA854EWqcwHG4ire4vbQH5U504eLtpYjrBwNC6XU',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: primaryMint)),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        primaryMint.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Level Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryMint.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: primaryMint, size: 16),
                      SizedBox(width: 4),
                      Text('LEVEL 12', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navyDeep)),
                    ],
                  ),
                ),
              ),
              // Title Text
              const Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'Clean the\nBay Area',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Join 124 others nearby',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          // 3D Button
          GestureDetector(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const QuestScreen()));
            },
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: primaryMint,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: shadowMint,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore, color: navyDeep, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'START IRL QUEST',
                    style: TextStyle(
                      color: navyDeep,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.recycling,
                  title: 'DAILY GOAL',
                  value: 'Collect 5kg',
                  content: Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), // Neutral track
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.6,
                      child: Container(decoration: BoxDecoration(color: primaryMint, borderRadius: BorderRadius.circular(4))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseAuth.instance.currentUser == null ? null : FirebaseFirestore.instance.collection('squads').where('memberIds', arrayContains: FirebaseAuth.instance.currentUser!.uid).snapshots(),
                  builder: (context, snapshot) {
                    String squadName = 'No Squad';
                    int memberCount = 0;
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                       final docs = snapshot.data!.docs;
                       // Pick a random squad or cycle to satisfy "alternate" requirement
                       final sq = docs[Random().nextInt(docs.length)].data() as Map<String, dynamic>;
                       squadName = sq['name'] ?? 'Squad';
                       final memberIds = sq['memberIds'] as List<dynamic>? ?? [];
                       memberCount = memberIds.length;
                    }
                    
                    return GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const SquadHubScreen()));
                      },
                      child: _buildStatCard(
                        icon: Icons.group,
                        title: 'SQUAD',
                        value: squadName,
                        content: Row(
                          children: [
                            _buildAvatar(Colors.grey.shade300, null),
                            if (memberCount > 1) Transform.translate(offset: const Offset(-8, 0), child: _buildAvatar(Colors.grey.shade400, null)),
                            if (memberCount > 2) Transform.translate(
                              offset: const Offset(-16, 0),
                              child: _buildAvatar(primaryMint, Text('+\${memberCount - 2}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: navyDeep))),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryMint.withOpacity(0.1), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryMint),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: navyDeep.withOpacity(0.4), letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDeep)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, Widget? child) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Center(child: child),
    );
  }

  Widget _buildHeatmapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOCAL HEATMAP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: navyDeep.withOpacity(0.5), letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Container(
            height: 128,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryMint.withOpacity(0.1), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDXoYElHR1N2g92JaP9GaLPFOInX1xGB8SE-JV2K66dk9mQV7EMMxLlyjj6-SjpZ8ZqGdVWkQtbkR3x6zfnql20jQQEeBnnkQb0DUWnQ6z7fvJvh6LqSNQbJ6C9jMbzaJrz8vrUcJ7IUy16Rw75Qo0AGoBCxoVQ5EYPaMfEhGmg5n6S2bKpGDwJedXCFcUaXrDZ6sU1CXgEEcks1Iw98cwcD8jPPxhzJcbJCkcryqY4W8NSKxtWTWQmf3zN3ZaUsEbAXXjfcC8DV_k',
                    fit: BoxFit.cover,
                  ),
                  Container(color: primaryMint.withOpacity(0.1)),
                  Center(
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: primaryMint.withOpacity(0.4), shape: BoxShape.circle),
                      child: Center(
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: primaryMint, 
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: Border(top: BorderSide(color: primaryMint.withOpacity(0.1))),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(Icons.home_filled, 'Home', 0),
            _buildNavIcon(Icons.swap_horiz, 'Exchange', 1),
            _buildNavIcon(Icons.map_outlined, 'Map', 2),
            _buildNavIcon(Icons.group_outlined, 'Social', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const InteractivePollutionMap()));
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isActive ? primaryMint.withOpacity(0.2) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isActive ? navyDeep : navyDeep.withOpacity(0.4)),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? navyDeep : navyDeep.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}