import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'level_utils.dart';

class FriendProfileScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const FriendProfileScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final String firstName = userData['firstName'] ?? 'Player';
    final String lastName = userData['lastName'] ?? '';
    final String username = userData['username'] ?? '';
    final int exp = userData['exp'] ?? 0;
    final int level = LevelUtils.calculateLevel(exp);
    final int questsCompleted = userData['questsCompleted'] ?? (exp ~/ 50);

    String memberSince = '2023';
    if (userData['createdAt'] != null) {
      try {
        DateTime dt;
        final createdAt = userData['createdAt'];
        if (createdAt is Timestamp) {
          dt = createdAt.toDate();
        } else if (createdAt is String) {
          dt = DateTime.parse(createdAt);
        } else {
          dt = DateTime.now();
        }
        const List<String> months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        memberSince = '${months[dt.month - 1]} ${dt.year}';
      } catch (e) {
        memberSince = '2023';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7), // background-light
      body: Stack(
        children: [
          // Background Gradient Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: CachedNetworkImage(
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuC50zq7WZyi8ZcICZxZOCUO8jw_SH5-RoeCozACtdnAt9qtnUkUCJANPTFlUbCNOWzTC7lK_NPWs5_Iqyjhbk0GI2iKizvqsG1N6DRTBJwWYq57NOVNRWLqxUJv0WnsR1s-tAqa1maTwlU5HCnmggWPpNLORjZoJBr2--3sSe1px9v-FkVX2_kDHhtIXOulV8ZGNyRBASolAXGgS7-uHZ2twDtYPNhgVBAakR-SA854EWqcwHG4ire4vbQH5U504eLtpYjrBwNC6XU',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Fade into content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF5F8F7), // Match background color
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF0A192F)),
              ),
            ),
          ),

          // Main Content
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Big Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF0077b6,
                      ).withOpacity(0.1), // ocean-blue
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 16),
                      ],
                    ),
                    child: const Icon(
                      Icons.surfing,
                      size: 64,
                      color: Color(0xFF0077b6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name and Username
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A192F),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0077b6).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'LEVEL',
                          '$level',
                          Icons.star,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'TOTAL EXP',
                          '$exp',
                          Icons.bolt,
                          const Color(0xFF25F4AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Eco Impact Panel
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.eco, color: Color(0xFF25F4AF)),
                            const SizedBox(width: 8),
                            Text(
                              'ECO IMPACT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0A192F).withOpacity(0.5),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildImpactRow('Quests Completed', '$questsCompleted'),
                        const Divider(height: 24),
                        _buildImpactRow(
                          'Friends in Squad',
                          '3',
                        ), // Dummy for now
                        const Divider(height: 24),
                        _buildImpactRow('Member Since', memberSince),
                      ],
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0A192F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0A192F).withOpacity(0.4),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A192F),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0077b6),
          ),
        ),
      ],
    );
  }
}
