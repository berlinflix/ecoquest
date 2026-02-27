import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/game_screen.dart';

/// Refined Park Intro V3 UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onPlay() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const GameScreen(),
        transitionsBuilder: (_, anim, s, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _onBack() {
    // In a real app this might pop the nav stack. 
    // Here we'll just exit the app if we are at the root.
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          return Stack(
            children: [
              // ── Background Image ──
              Positioned.fill(
                child: Image.asset(
                  'assets/images/home_bg.jpg',
                  package: 'ecoquest',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey.shade200),
                ),
              ),

              // ── Header (Back Button & Title) ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: _onBack,
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF0D161C), // primary-navy
                            size: 32,
                          ),
                        ),
                        // Title
                        Text(
                          'ECOQUEST',
                          style: GoogleFonts.splineSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D161C),
                            letterSpacing: 2.5, // 0.15em tracking approx
                            decoration: TextDecoration.none,
                          ),
                        ),
                        // Empty spacer to balance the row
                        const SizedBox(width: 32),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Play Button (Teal Shadow) ──
              Center(
                child: AnimatedBuilder(
                  animation: _hoverController,
                  builder: (context, child) {
                    final double scale = 1.0 + (_hoverController.value * 0.03);
                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: _onPlay,
                        child: Container(
                          width: (w * 0.8).clamp(240.0, 320.0),
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x662DD4BF), // rgba(45, 212, 191, 0.4) Soft Teal
                                blurRadius: 25,
                                spreadRadius: -5,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'PLAY',
                            style: GoogleFonts.splineSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D161C), // primary-navy
                              letterSpacing: 2.0, // 0.1em tracking
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Footer indicator ──
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 128,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D161C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
