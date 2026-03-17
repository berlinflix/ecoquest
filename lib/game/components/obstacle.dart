import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../eco_dash_game.dart';
import 'player.dart';

class Obstacle extends PositionComponent with HasGameReference<EcoDashGame>, CollisionCallbacks {
  double _animTimer = 0;
  bool _exploding = false;
  double _explosionTimer = 0;

  Obstacle({required Vector2 position})
      : super(position: position, size: Vector2(32, 32), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: Vector2(24, 28), position: Vector2(4, 2)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameState != GameState.playing && !_exploding) return;

    if (!_exploding) {
      position.x -= game.gameSpeed * dt;
    }
    _animTimer += dt;

    if (_exploding) {
      _explosionTimer += dt;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EcoPlayer && !_exploding) {
      _exploding = true;
      _explosionTimer = 0;
      // Instant game over
      game.gameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_exploding) {
      _drawExplosion(canvas);
      return;
    }

    // Toxic waste barrel
    final barrelPaint = Paint()..color = const Color(0xFF8B0000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(6, 4, 20, 26), const Radius.circular(4)),
      barrelPaint,
    );

    // Stripes
    final stripePaint = Paint()..color = const Color(0xFFA52A2A);
    canvas.drawRect(const Rect.fromLTWH(6, 10, 20, 3), stripePaint);
    canvas.drawRect(const Rect.fromLTWH(6, 22, 20, 3), stripePaint);

    // Hazard triangle
    final hazardPaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawPath(
      Path()..moveTo(16, 8)..lineTo(22, 18)..lineTo(10, 18)..close(),
      hazardPaint,
    );
    canvas.drawRect(const Rect.fromLTWH(15, 10, 2, 5), barrelPaint);
    canvas.drawCircle(const Offset(16, 16.5), 1, barrelPaint);

    // Animated toxic bubbles
    final bubbleAlpha = (sin(_animTimer * 4) * 0.5 + 0.5).clamp(0.0, 1.0);
    final bubblePaint = Paint()..color = Color.fromRGBO(76, 175, 80, bubbleAlpha);
    final bubbleY = 2.0 - sin(_animTimer * 3) * 4;
    canvas.drawCircle(Offset(20, bubbleY), 3, bubblePaint);
    canvas.drawCircle(Offset(24, bubbleY - 2), 2, bubblePaint);
  }

  void _drawExplosion(Canvas canvas) {
    final t = _explosionTimer;
    final progress = (t / 0.8).clamp(0.0, 1.0);

    // Multiple expanding rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress - i * 0.1).clamp(0.0, 1.0);
      final radius = ringProgress * 50 + 8;
      final alpha = (1.0 - ringProgress).clamp(0.0, 1.0);

      // Outer fire ring
      final firePaint = Paint()
        ..color = Color.fromRGBO(255, 87, 34, alpha * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 - ringProgress * 3;
      canvas.drawCircle(const Offset(16, 16), radius, firePaint);
    }

    // Central fireball
    final coreAlpha = (1.0 - progress * 1.2).clamp(0.0, 1.0);
    final coreRadius = 10 + progress * 15;

    // Orange glow
    canvas.drawCircle(
      const Offset(16, 16),
      coreRadius,
      Paint()..color = Color.fromRGBO(255, 152, 0, coreAlpha * 0.8),
    );

    // Yellow core
    canvas.drawCircle(
      const Offset(16, 16),
      coreRadius * 0.6,
      Paint()..color = Color.fromRGBO(255, 235, 59, coreAlpha),
    );

    // White flash at start
    if (progress < 0.2) {
      final flashAlpha = (1.0 - progress / 0.2).clamp(0.0, 1.0);
      canvas.drawCircle(
        const Offset(16, 16),
        coreRadius * 0.3,
        Paint()..color = Color.fromRGBO(255, 255, 255, flashAlpha),
      );
    }

    // Flying debris particles
    final rng = Random(42); // fixed seed for consistent particles
    for (int i = 0; i < 8; i++) {
      final angle = rng.nextDouble() * 3.14159 * 2;
      final dist = progress * (30 + rng.nextDouble() * 30);
      final px = 16 + cos(angle) * dist;
      final py = 16 + sin(angle) * dist;
      final particleAlpha = (1.0 - progress).clamp(0.0, 1.0);
      final pSize = (3 - progress * 2).clamp(1.0, 3.0);

      final colors = [
        Color.fromRGBO(255, 87, 34, particleAlpha),   // orange
        Color.fromRGBO(255, 193, 7, particleAlpha),    // amber
        Color.fromRGBO(100, 100, 100, particleAlpha),  // smoke
      ];
      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()..color = colors[i % 3],
      );
    }

    // Smoke puffs (darker, fade last)
    for (int i = 0; i < 4; i++) {
      final smokeProgress = (progress - 0.2).clamp(0.0, 1.0);
      final angle = i * 3.14159 / 2 + 0.5;
      final dist = smokeProgress * 25;
      final sx = 16 + cos(angle) * dist;
      final sy = 16 + sin(angle) * dist - smokeProgress * 10;
      final smokeAlpha = (0.4 - smokeProgress * 0.4).clamp(0.0, 0.4);
      canvas.drawCircle(
        Offset(sx, sy),
        6 + smokeProgress * 8,
        Paint()..color = Color.fromRGBO(80, 80, 80, smokeAlpha),
      );
    }
  }
}
