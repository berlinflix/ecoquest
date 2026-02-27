import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A collectible item placed in the game world.
class Collectible {
  double x;
  double y;
  final double radius;
  bool isCollected;
  final Paint paint;

  Collectible({
    required this.x,
    required this.y,
    this.radius = 22,
    this.isCollected = false,
    Paint? paint,
  }) : paint =
           paint ??
           (Paint()
             ..color = const Color(0xFF4CAF50)
             ..style = PaintingStyle.fill);

  /// Optional sprite image — random litter type.
  ui.Image? sprite;

  /// Draw the collectible (only if not yet collected).
  void draw(Canvas canvas) {
    if (isCollected) return;
    if (sprite != null) {
      final double w = sprite!.width.toDouble();
      final double h = sprite!.height.toDouble();
      final Rect src = Rect.fromLTWH(0, 0, w, h);
      final Rect dst = Rect.fromCenter(
        center: Offset(x, y),
        width: radius * 2,
        height: radius * 2,
      );
      canvas.drawImageRect(sprite!, src, dst, Paint());
    } else {
      canvas.drawCircle(Offset(x, y), radius, paint);
      final glowPaint = Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(x, y), radius + 4, glowPaint);
    }
  }
}
