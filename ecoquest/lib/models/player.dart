import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/world.dart';
import 'weapon.dart';

/// A simple 2D player entity with position, velocity, health, and rendering.
class Player {
  double x;
  double y;
  double vx;
  double vy;
  final double radius;
  final Paint paint;

  /// Health properties.
  int maxHp;
  int currentHp;

  /// Invincibility timer — while > 0, the player cannot take damage.
  double invincibilityTimer;

  /// Active orbital weapons surrounding the player.
  late List<Weapon> activeWeapons;

  /// Optional sprite image. When set, the player renders this instead of the
  /// fallback teal circle.
  ui.Image? spriteImage;

  /// Internal frame counter for blink effect during invincibility.
  int _blinkFrame = 0;

  Player({
    this.x = 0,
    this.y = 0,
    this.vx = 0,
    this.vy = 0,
    this.radius = 36,
    this.maxHp = 100,
    this.currentHp = 100,
    this.invincibilityTimer = 0,
    this.spriteImage,
    Paint? paint,
  }) : paint =
           paint ??
           (Paint()
             ..color = const Color(0xFF00E5CC)
             ..style = PaintingStyle.fill) {
    // Initialize with two test orbital weapons.
    activeWeapons = [
      Weapon(
        hitboxRadius: 12.0,
        orbitDistance: 80.0,
        revolutionSpeed: 4.0,
        damage: 0.2, // Light, fast weapon
        currentAngle: 0.0,
      ),
      Weapon(
        hitboxRadius: 16.0,
        orbitDistance: 120.0,
        revolutionSpeed: 2.5,
        damage: 1.0, // Heavy, slow weapon
        currentAngle: 3.14,
      ),
    ];
  }

  /// Take damage if not currently invincible.
  void takeDamage(int amount) async {
    if (invincibilityTimer > 0) return;
    currentHp = (currentHp - amount).clamp(0, maxHp);
    invincibilityTimer = 1.0; // 1 second of i-frames

    // Intense rapid pulse vibration for ~1 second (10 pulses * 100ms)
    for (int i = 0; i < 10; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Update position using kinematic equations, clamp to world, tick i-timer.
  void update(double dt) {
    x += vx * dt;
    y += vy * dt;

    // Clamp to world boundaries, accounting for radius.
    x = x.clamp(radius, worldWidth - radius);
    y = y.clamp(radius, worldHeight - radius);

    // Tick invincibility timer.
    if (invincibilityTimer > 0) {
      invincibilityTimer -= dt;
      _blinkFrame++;
    } else {
      _blinkFrame = 0;
    }

    // Update weapons.
    for (final weapon in activeWeapons) {
      weapon.update(dt, x, y);
    }
  }

  /// Draw the player and floating health bar.
  void draw(Canvas canvas) {
    // ── Blink effect: skip rendering every other 4 frames while invincible ──
    final bool visible = invincibilityTimer <= 0 || (_blinkFrame ~/ 4) % 2 == 0;

    if (visible) {
      if (spriteImage != null) {
        final double w = spriteImage!.width.toDouble();
        final double h = spriteImage!.height.toDouble();
        final Rect src = Rect.fromLTWH(0, 0, w, h);
        final Rect dst = Rect.fromCenter(
          center: Offset(x, y),
          width: radius * 2,
          height: radius * 2,
        );
        canvas.drawImageRect(spriteImage!, src, dst, Paint());
      } else {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }

    // ── Draw weapons ──
    for (final weapon in activeWeapons) {
      weapon.draw(canvas);
    }

    // ── Health bar (always visible, floats above the player) ──
    const double barWidth = 40;
    const double barHeight = 5;
    final double barX = x - barWidth / 2;
    final double barY = y - radius - 12;

    // Gray background.
    final bgPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // Red foreground (proportional to HP).
    final double hpFraction = (currentHp / maxHp).clamp(0.0, 1.0);
    final hpColor = hpFraction > 0.5
        ? const Color(0xFF4CAF50) // green when healthy
        : hpFraction > 0.25
        ? const Color(0xFFFFC107) // amber when low
        : const Color(0xFFF44336); // red when critical

    final fgPaint = Paint()
      ..color = hpColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * hpFraction, barHeight),
        const Radius.circular(2),
      ),
      fgPaint,
    );
  }
}
