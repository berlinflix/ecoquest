import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../eco_dash_game.dart';
import 'player.dart';

/// Trash types: 0=banana peel, 1=soda can, 2=plastic bottle, 3=paper bag, 4=chip bag
class Collectible extends PositionComponent with HasGameReference<EcoDashGame>, CollisionCallbacks {
  double _floatTimer = 0;
  final double _startY;
  bool _collected = false;
  double _collectAnim = 0;
  final int trashType;

  Collectible({required Vector2 position, this.trashType = 0})
      : _startY = position.y,
        super(position: position, size: Vector2(28, 28), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 14));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameState != GameState.playing) return;

    position.x -= game.gameSpeed * dt;

    // Float animation
    _floatTimer += dt * 3;
    position.y = _startY + sin(_floatTimer) * 5;

    // Collection animation
    if (_collected) {
      _collectAnim += dt * 4;
      if (_collectAnim > 1.0) {
        removeFromParent();
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EcoPlayer && !_collected) {
      _collected = true;
      game.collectItem();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_collected) {
      // "+10" float-up text effect
      final alpha = (1.0 - _collectAnim).clamp(0.0, 1.0);
      final textPaint = TextPaint(
        style: TextStyle(
          color: Color.fromRGBO(76, 175, 80, alpha),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPaint.render(canvas, '+10', Vector2(6, -_collectAnim * 20));
      return;
    }

    switch (trashType) {
      case 0: _drawBananaPeel(canvas); break;
      case 1: _drawSodaCan(canvas); break;
      case 2: _drawPlasticBottle(canvas); break;
      case 3: _drawPaperBag(canvas); break;
      case 4: _drawChipBag(canvas); break;
    }
  }

  void _drawBananaPeel(Canvas canvas) {
    final yellowPaint = Paint()..color = const Color(0xFFFFEB3B);
    final darkYellow = Paint()..color = const Color(0xFFFBC02D);
    final brownPaint = Paint()..color = const Color(0xFF8D6E63);

    // Banana curve
    final path = Path()
      ..moveTo(8, 20)
      ..quadraticBezierTo(4, 10, 10, 4)
      ..quadraticBezierTo(16, 0, 22, 6)
      ..quadraticBezierTo(24, 14, 18, 22)
      ..close();
    canvas.drawPath(path, yellowPaint);

    // Brown spots
    canvas.drawCircle(const Offset(12, 10), 2, brownPaint);
    canvas.drawCircle(const Offset(16, 14), 1.5, brownPaint);

    // Peel flaps
    final peelPath = Path()
      ..moveTo(8, 20)
      ..lineTo(4, 26)
      ..lineTo(10, 22);
    canvas.drawPath(peelPath, darkYellow);

    final peelPath2 = Path()
      ..moveTo(18, 22)
      ..lineTo(24, 26)
      ..lineTo(22, 20);
    canvas.drawPath(peelPath2, darkYellow);
  }

  void _drawSodaCan(Canvas canvas) {
    final redPaint = Paint()..color = const Color(0xFFE53935);
    final silverPaint = Paint()..color = const Color(0xFFBDBDBD);
    final whitePaint = Paint()..color = Colors.white;

    // Can body
    final canRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 4, 12, 20),
      const Radius.circular(3),
    );
    canvas.drawRRect(canRect, redPaint);

    // Silver top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 4, 12, 4),
        const Radius.circular(3),
      ),
      silverPaint,
    );

    // Tab
    canvas.drawCircle(const Offset(14, 6), 2, Paint()..color = const Color(0xFF9E9E9E));

    // Label line
    canvas.drawRect(const Rect.fromLTWH(9, 14, 10, 2), whitePaint);
  }

  void _drawPlasticBottle(Canvas canvas) {
    final bluePaint = Paint()..color = const Color(0xFF42A5F5);
    final lightBlue = Paint()..color = const Color(0xFF90CAF9);
    final capPaint = Paint()..color = const Color(0xFF1976D2);

    // Bottle body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 10, 10, 16),
        const Radius.circular(4),
      ),
      bluePaint,
    );

    // Neck
    canvas.drawRect(const Rect.fromLTWH(12, 4, 4, 8), bluePaint);

    // Cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(11, 2, 6, 4),
        const Radius.circular(2),
      ),
      capPaint,
    );

    // Water reflection
    canvas.drawRect(const Rect.fromLTWH(11, 14, 2, 8), lightBlue);
  }

  void _drawPaperBag(Canvas canvas) {
    final brownPaint = Paint()..color = const Color(0xFFA1887F);
    final darkBrown = Paint()..color = const Color(0xFF8D6E63);

    // Bag body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 6, 16, 18),
        const Radius.circular(2),
      ),
      brownPaint,
    );

    // Fold lines
    canvas.drawLine(
      const Offset(6, 10), const Offset(22, 10),
      darkBrown..strokeWidth = 1,
    );
    // Crumpled top
    final topPath = Path()
      ..moveTo(6, 6)
      ..lineTo(10, 3)
      ..lineTo(14, 6)
      ..lineTo(18, 3)
      ..lineTo(22, 6);
    canvas.drawPath(topPath, darkBrown..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawChipBag(Canvas canvas) {
    final orangePaint = Paint()..color = const Color(0xFFFF9800);
    final redPaint = Paint()..color = const Color(0xFFE65100);
    final yellowPaint = Paint()..color = const Color(0xFFFFEB3B);

    // Bag body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 4, 14, 20),
        const Radius.circular(3),
      ),
      orangePaint,
    );

    // Zigzag pattern
    final zigzag = Path()
      ..moveTo(7, 12)
      ..lineTo(11, 8)
      ..lineTo(14, 12)
      ..lineTo(17, 8)
      ..lineTo(21, 12);
    canvas.drawPath(zigzag, redPaint..style = PaintingStyle.stroke..strokeWidth = 2);

    // "chip" text placeholder (a small yellow rectangle label)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 15, 8, 4),
        const Radius.circular(1),
      ),
      yellowPaint,
    );
  }
}
