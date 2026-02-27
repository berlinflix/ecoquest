import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A tree used as a visual boundary marker around the world perimeter.
class Tree {
  final double x;
  final double y;
  final double radius;
  final Paint paint;

  /// Optional sprite image. Falls back to a dark green circle if null.
  ui.Image? sprite;

  Tree({
    required this.x,
    required this.y,
    this.radius = 30,
    this.sprite,
    Paint? paint,
  }) : paint =
           paint ??
           (Paint()
             ..color = const Color(0xFF1B5E20)
             ..style = PaintingStyle.fill);

  /// Draw the tree. Uses [sprite] if available, otherwise a dark green circle
  /// with a lighter canopy ring.
  void draw(Canvas canvas) {
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
      // Trunk / core.
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Canopy highlight ring.
      final canopyPaint = Paint()
        ..color = const Color(0xFF2E7D32).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(x, y), radius + 2, canopyPaint);
    }
  }
}
