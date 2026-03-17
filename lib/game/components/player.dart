import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../eco_dash_game.dart';
import 'platform_block.dart';

class EcoPlayer extends PositionComponent with HasGameReference<EcoDashGame>, CollisionCallbacks {
  static const double _gravity = 980.0;
  static const double _jumpForce = -440.0;
  static const double _maxFallSpeed = 650.0;

  double velocityY = 0;
  bool isOnGround = false;
  int _jumpsRemaining = 2;
  double _animTimer = 0;
  int _animFrame = 0;

  // Previous Y for reliable collision
  double _previousY = 0;

  EcoPlayer() : super(size: Vector2(36, 44), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: Vector2(28, 40), position: Vector2(4, 2)));
  }

  void jump() {
    if (_jumpsRemaining > 0) {
      velocityY = _jumpForce;
      isOnGround = false;
      _jumpsRemaining--;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.gameState != GameState.playing) return;

    _previousY = position.y;

    // Apply gravity
    velocityY += _gravity * dt;
    if (velocityY > _maxFallSpeed) velocityY = _maxFallSpeed;

    position.y += velocityY * dt;

    // Check if walked off edge
    if (isOnGround) {
      bool stillOnPlatform = false;
      for (final p in game.world.children.whereType<PlatformBlock>()) {
        if (_isStandingOn(p)) {
          stillOnPlatform = true;
          break;
        }
      }
      if (!stillOnPlatform) {
        isOnGround = false;
        _jumpsRemaining = 1;
      }
    }

    // Animation
    _animTimer += dt;
    if (_animTimer > 0.1) {
      _animTimer = 0;
      _animFrame = (_animFrame + 1) % 4;
    }

    // Fall off screen = death
    if (position.y > game.size.y + 100) {
      game.gameOver();
    }
  }

  bool _isStandingOn(PlatformBlock p) {
    final playerLeft = position.x - 14;
    final playerRight = position.x + 14;
    return playerRight > p.position.x &&
        playerLeft < p.position.x + p.blockSize.x &&
        (position.y - p.position.y).abs() < 5;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is PlatformBlock) {
      final platformTop = other.position.y;
      final platformBottom = other.position.y + other.blockSize.y;
      final playerTop = position.y - size.y; // top of player (since anchor=bottomCenter)

      if (velocityY >= 0 && _previousY <= platformTop + 15) {
        // LANDING on top: player is falling and was above the platform
        position.y = platformTop;
        velocityY = 0;
        isOnGround = true;
        _jumpsRemaining = 2;
      } else if (velocityY < 0 && playerTop < platformBottom && _previousY > platformTop + 5) {
        // HEAD BONK: jumping up and hitting the bottom of a platform (Mario-style)
        velocityY = 100; // bounce back down
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final bodyPaint = Paint()..color = const Color(0xFF5EC7DB);
    final darkPaint = Paint()..color = const Color(0xFF3A8FA0);
    final whitePaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = Colors.black;
    final beakPaint = Paint()..color = const Color(0xFFFFB74D);

    final bobOffset = isOnGround ? ((_animFrame % 2 == 0) ? -2.0 : 0.0) : -3.0;

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 4 + bobOffset, 28, 32), const Radius.circular(14)),
      bodyPaint,
    );

    // Belly
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10, 14 + bobOffset, 16, 18), const Radius.circular(8)),
      Paint()..color = const Color(0xFF8EDCE8),
    );

    // Eye
    canvas.drawCircle(Offset(22, 14 + bobOffset), 7, whitePaint);
    canvas.drawCircle(Offset(24, 14 + bobOffset), 4, blackPaint);
    canvas.drawCircle(Offset(25, 13 + bobOffset), 1.5, whitePaint);

    // Beak
    canvas.drawPath(
      Path()..moveTo(29, 16 + bobOffset)..lineTo(36, 18 + bobOffset)..lineTo(29, 20 + bobOffset)..close(),
      beakPaint,
    );

    // Crown feather
    canvas.drawPath(
      Path()..moveTo(16, 4 + bobOffset)..lineTo(14, -4 + bobOffset)..lineTo(20, 2 + bobOffset)..lineTo(18, -2 + bobOffset)..lineTo(22, 4 + bobOffset)..close(),
      darkPaint,
    );

    // Legs
    if (isOnGround) {
      final l1 = _animFrame < 2 ? 0.0 : 4.0;
      final l2 = _animFrame < 2 ? 4.0 : 0.0;
      canvas.drawRect(Rect.fromLTWH(12 + l1, 34 + bobOffset, 4, 8), darkPaint);
      canvas.drawRect(Rect.fromLTWH(20 + l2, 34 + bobOffset, 4, 8), darkPaint);
    } else {
      canvas.drawRect(Rect.fromLTWH(14, 34 + bobOffset, 4, 5), darkPaint);
      canvas.drawRect(Rect.fromLTWH(20, 34 + bobOffset, 4, 5), darkPaint);
    }
  }
}
