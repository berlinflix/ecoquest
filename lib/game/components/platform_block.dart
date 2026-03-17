import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../eco_dash_game.dart';

class PlatformBlock extends PositionComponent with HasGameReference<EcoDashGame> {
  final bool isGround;
  final Vector2 blockSize;

  PlatformBlock({
    required Vector2 position,
    required this.blockSize,
    this.isGround = false,
  }) : super(position: position, size: blockSize, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: blockSize));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameState == GameState.playing) {
      position.x -= game.gameSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isGround) {
      // Grass top
      final grassPaint = Paint()..color = const Color(0xFF4CAF50);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, blockSize.x, 8),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        grassPaint,
      );

      // Light grass highlight
      final lightGrass = Paint()..color = const Color(0xFF66BB6A);
      canvas.drawRect(Rect.fromLTWH(0, 2, blockSize.x, 3), lightGrass);

      // Dirt body
      final dirtPaint = Paint()..color = const Color(0xFF5D4037);
      canvas.drawRect(Rect.fromLTWH(0, 8, blockSize.x, blockSize.y - 8), dirtPaint);

      // Dirt texture dots
      final darkDirt = Paint()..color = const Color(0xFF4E342E);
      for (double x = 6; x < blockSize.x - 6; x += 14) {
        for (double y = 12; y < blockSize.y - 4; y += 10) {
          canvas.drawCircle(Offset(x, y), 2, darkDirt);
        }
      }
    } else {
      // Floating platform - stone-like
      final stonePaint = Paint()..color = const Color(0xFF78909C);
      final stoneRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, blockSize.x, blockSize.y),
        const Radius.circular(6),
      );
      canvas.drawRRect(stoneRect, stonePaint);

      // Highlight on top
      final highlight = Paint()..color = const Color(0xFF90A4AE);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(2, 0, blockSize.x - 4, 6),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        highlight,
      );

      // Moss detail
      final mossPaint = Paint()..color = const Color(0xFF4CAF50);
      canvas.drawRect(Rect.fromLTWH(4, 0, 12, 3), mossPaint);
      canvas.drawRect(Rect.fromLTWH(blockSize.x - 16, 0, 10, 3), mossPaint);
    }
  }
}
