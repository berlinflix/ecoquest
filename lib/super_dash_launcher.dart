// Super Dash-inspired game launcher
// Game inspired by: https://github.com/flutter/super_dash
// © Flutter Team & Very Good Ventures (BSD-3-Clause)

import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game/eco_dash_game.dart';

class SuperDashLauncher extends StatefulWidget {
  const SuperDashLauncher({super.key});

  @override
  State<SuperDashLauncher> createState() => _SuperDashLauncherState();
}

class _SuperDashLauncherState extends State<SuperDashLauncher> {
  late final EcoDashGame _game;

  @override
  void initState() {
    super.initState();
    _game = EcoDashGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'MainMenu': (context, game) => _MainMenuOverlay(game: _game),
          'HUD': (context, game) => _HudOverlay(game: _game),
          'GameOver': (context, game) => _GameOverOverlay(game: _game),
        },
        initialActiveOverlays: const ['MainMenu'],
      ),
    );
  }
}

// ─── MAIN MENU ───────────────────────────────────────────────
class _MainMenuOverlay extends StatelessWidget {
  final EcoDashGame game;
  const _MainMenuOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A1628).withValues(alpha: 0.9),
            const Color(0xFF1B3A5C).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            const Spacer(),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF5EC7DB), Color(0xFF4CAF50)],
              ).createShader(bounds),
              child: Text(
                'ECO',
                style: GoogleFonts.anton(
                  fontSize: 72,
                  color: Colors.white,
                  letterSpacing: 8,
                  height: 0.9,
                ),
              ),
            ),
            Text(
              'DASH',
              style: GoogleFonts.bebasNeue(
                fontSize: 48,
                color: Colors.white,
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Collect trash • Avoid hazards • Save the planet',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: () => game.startGame(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5EC7DB), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5EC7DB).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'PLAY',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: Colors.white54, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to jump • Double-tap for double jump',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Inspired by Super Dash © Flutter Team & Very Good Ventures\nBSD-3-Clause License',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HUD (live-updating) ────────────────────────────────────
class _HudOverlay extends StatefulWidget {
  final EcoDashGame game;
  const _HudOverlay({required this.game});

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pill(Icons.delete_outline, '${g.trashCollected}', const Color(0xFF4CAF50)),
                _pill(Icons.star, '${g.score}', const Color(0xFFFFEB3B)),
                _pill(Icons.straighten, '${(g.distanceTravelled / 10).toInt()}m', const Color(0xFF5EC7DB)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            if (g.difficultyLevel > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15 + g.difficultyLevel * 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'LVL ${g.difficultyLevel}',
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── GAME OVER ──────────────────────────────────────────────
class _GameOverOverlay extends StatelessWidget {
  final EcoDashGame game;
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    final isNewHigh = game.score >= game.highScore && game.highScore > 0;
    final isNewDist = game.distanceTravelled >= game.bestDistance && game.bestDistance > 0;

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
                ).createShader(bounds),
                child: Text(
                  'GAME OVER',
                  style: GoogleFonts.anton(fontSize: 48, color: Colors.white, letterSpacing: 4),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3A5C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF5EC7DB).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    // Big score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFEB3B), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '${game.score}',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Text('SCORE', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                    const SizedBox(height: 14),
                    // Mini stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat(Icons.delete_outline, '${game.trashCollected}', 'TRASH', const Color(0xFF4CAF50)),
                        _stat(Icons.straighten, '${(game.distanceTravelled / 10).toInt()}m', 'DIST', const Color(0xFF5EC7DB)),
                        _stat(Icons.speed, 'LV ${game.difficultyLevel}', 'LEVEL', Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isNewHigh) _badge('🏆 NEW HIGH SCORE!', const Color(0xFFFFD700)),
                    if (isNewDist) _badge('📏 NEW BEST DISTANCE!', const Color(0xFF5EC7DB)),
                    const SizedBox(height: 4),
                    Text(
                      'Best: ${game.highScore}  •  ${(game.bestDistance / 10).toInt()}m',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Retry button
              GestureDetector(
                onTap: () => game.startGame(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF5EC7DB), Color(0xFF4CAF50)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5EC7DB).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.replay, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text('RETRY', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Exit
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text('EXIT', style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String val, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
