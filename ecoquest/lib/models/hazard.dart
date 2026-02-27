import 'dart:math';

import 'package:flutter/material.dart';

/// A static hazard (spike trap) used to test the health system.
class Hazard {
  final double x;
  final double y;
  final double radius;
  final Paint paint;

  /// Internal pulse counter for glow animation.
  double _pulse = 0;

  Hazard({required this.x, required this.y, this.radius = 20, Paint? paint})
    : paint =
          paint ??
          (Paint()
            ..color = const Color(0xFFF44336)
            ..style = PaintingStyle.fill);

  /// Advance the pulse animation.
  void update(double dt) {
    _pulse += dt * 3;
  }

  /// Draw the hazard as a pulsing red circle.
  void draw(Canvas canvas) {
    // Pulsing glow ring.
    final double glowRadius = max(0.1, radius + 4 + sin(_pulse) * 3);
    final glowPaint = Paint()
      ..color = const Color(0xFFF44336).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(x, y), glowRadius, glowPaint);

    // Core circle.
    canvas.drawCircle(Offset(x, y), radius, paint);

    // Inner warning icon — small white cross.
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const double arm = 7;
    canvas.drawLine(
      Offset(x - arm, y - arm),
      Offset(x + arm, y + arm),
      crossPaint,
    );
    canvas.drawLine(
      Offset(x + arm, y - arm),
      Offset(x - arm, y + arm),
      crossPaint,
    );
  }
}
