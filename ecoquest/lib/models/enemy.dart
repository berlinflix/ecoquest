import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'collectible.dart';

/// Two distinct enemy types with different stats.
enum EnemyType { human, animal }

/// A chasing enemy that pursues the player and drops litter (collectibles).
class Enemy {
  double x;
  double y;
  final double radius;
  final double speed;
  final Paint paint;
  final EnemyType type;
  final int damageToPlayer;
  final double maxHp;
  double currentHp;

  /// Optional sprite image drawn instead of the default circle.
  ui.Image? sprite;

  /// Timer for litter drops — drops a new Collectible every 5 seconds.
  double litterTimer;

  Enemy({
    required this.x,
    required this.y,
    required this.type,
    double? radius,
    double? speed,
    int? damageToPlayer,
    double? maxHp,
    this.litterTimer = 0,
    Paint? paint,
  }) : radius = radius ?? 32,
       speed = speed ?? (type == EnemyType.human ? 60 : 100),
       damageToPlayer = damageToPlayer ?? (type == EnemyType.human ? 20 : 10),
       maxHp = maxHp ?? (type == EnemyType.human ? 50.0 : 30.0),
       currentHp = maxHp ?? (type == EnemyType.human ? 50.0 : 30.0),
       paint =
           paint ??
           (Paint()
             ..color = type == EnemyType.human
                 ? const Color(0xFF9C27B0) // purple
                 : const Color(0xFFFF9800) // orange
             ..style = PaintingStyle.fill);

  /// Take damage (for future combat).
  void takeDamage(double amount) {
    currentHp = (currentHp - amount).clamp(0.0, maxHp);
  }

  bool get isDead => currentHp <= 0.0;

  void update(
    double dt,
    double playerX,
    double playerY,
    List<Collectible> worldCollectibles,
    List<Enemy> allEnemies,
  ) {
    // ── Separation vector (push away from siblings) ──
    double sepX = 0;
    double sepY = 0;
    int neighbors = 0;

    for (final other in allEnemies) {
      if (identical(this, other)) continue;

      final double dx = x - other.x;
      final double dy = y - other.y;
      final double dist = sqrt(dx * dx + dy * dy);
      final double minSafeDist =
          radius +
          other.radius +
          20.0; // 20 units of buffer (invisible barrier)

      if (dist > 0 && dist < minSafeDist) {
        // Push force inversely proportional to distance
        final double pushStrength = (minSafeDist - dist) / dist;
        sepX += dx * pushStrength;
        sepY += dy * pushStrength;
        neighbors++;
      }
    }

    if (neighbors > 0) {
      sepX /= neighbors;
      sepY /= neighbors;
    }

    // ── Pursuit vector ──
    final double angle = atan2(playerY - y, playerX - x);
    final double chaseX = cos(angle) * speed;
    final double chaseY = sin(angle) * speed;

    // Combine behaviors: weighted heavily towards separation when overlapping
    final double finalVx = chaseX + (sepX * speed * 3.5);
    final double finalVy = chaseY + (sepY * speed * 3.5);

    x += finalVx * dt;
    y += finalVy * dt;

    // Litter logic (every 8 seconds).
    litterTimer += dt;
    if (litterTimer >= 8.0) {
      litterTimer = 0.0;
      worldCollectibles.add(Collectible(x: x, y: y));
    }
  }

  /// Draw the enemy. Uses sprite if available, otherwise falls back to circle.
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
      // Outer ring.
      final ringPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(x, y), radius + 4, ringPaint);

      // Core circle.
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Inner marker — eye for human, dot for animal.
      final markerPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      if (type == EnemyType.human) {
        canvas.drawCircle(Offset(x, y), 4, markerPaint);
      } else {
        // Two small eyes for animal.
        canvas.drawCircle(Offset(x - 5, y - 3), 2.5, markerPaint);
        canvas.drawCircle(Offset(x + 5, y - 3), 2.5, markerPaint);
      }
    }

    // ── Health bar (always drawn on top) ──
    const double barWidth = 30;
    const double barHeight = 4;
    final double barX = x - barWidth / 2;
    final double barY = y - radius - 8;

    // Gray background.
    final bgPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(1),
      ),
      bgPaint,
    );

    // Red foreground (proportional to HP).
    final double hpFraction = (currentHp / maxHp).clamp(0.0, 1.0);
    if (hpFraction > 0) {
      final fgPaint = Paint()
        ..color = const Color(0xFFF44336)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barWidth * hpFraction, barHeight),
          const Radius.circular(1),
        ),
        fgPaint,
      );
    }
  }
}
