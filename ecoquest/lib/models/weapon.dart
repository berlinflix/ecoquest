import 'dart:math';

import 'package:flutter/material.dart';

/// An orbital weapon that constantly revolves around the player
/// and deals continuous damage to enemies on contact.
class Weapon {
  double x;
  double y;
  final double hitboxRadius;
  final double orbitDistance;

  /// Revolution speed in radians per second.
  double revolutionSpeed; // Mutable for upgrades

  /// Damage applied per frame of contact.
  final double damage;

  double currentAngle;
  final Paint paint;

  Weapon({
    this.x = 0,
    this.y = 0,
    required this.hitboxRadius,
    required this.orbitDistance,
    required this.revolutionSpeed,
    required this.damage,
    this.currentAngle = 0.0,
    Paint? paint,
  }) : paint =
           paint ??
           (Paint()
             ..color =
                 const Color(0xFF03A9F4) // Light Blue
             ..style = PaintingStyle.fill);

  /// Calculate new orbital position relative to the player.
  void update(double dt, double playerX, double playerY) {
    currentAngle += revolutionSpeed * dt;
    x = playerX + (cos(currentAngle) * orbitDistance);
    y = playerY + (sin(currentAngle) * orbitDistance);
  }

  /// Draw the weapon as a filled circle with a soft glow.
  void draw(Canvas canvas) {
    // Soft outer glow.
    final glowPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), hitboxRadius + 3, glowPaint);

    // Core weapon body.
    canvas.drawCircle(Offset(x, y), hitboxRadius, paint);

    // Bright center highlight.
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), hitboxRadius * 0.4, highlightPaint);
  }
}
