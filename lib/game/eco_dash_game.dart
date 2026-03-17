// EcoDash - A platformer game inspired by Super Dash
// Original inspiration: https://github.com/flutter/super_dash
// © Flutter Team & Very Good Ventures (BSD-3-Clause)

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;

import 'components/player.dart';
import 'components/platform_block.dart';
import 'components/collectible.dart';
import 'components/obstacle.dart';

enum GameState { menu, playing, gameOver }

class EcoDashGame extends FlameGame with TapCallbacks, HasCollisionDetection {
  GameState gameState = GameState.menu;
  int score = 0;
  int highScore = 0;
  double bestDistance = 0;
  double gameSpeed = 200.0;
  double distanceTravelled = 0;
  int trashCollected = 0;
  final Random _random = Random();

  late EcoPlayer player;
  double _spawnTimer = 0;
  double _collectibleTimer = 0;
  double _obstacleTimer = 0;
  double _speedIncreaseTimer = 0;

  // Difficulty scaling
  int get difficultyLevel => (distanceTravelled / 3000).floor().clamp(0, 10);
  double get gapChance => (0.08 + difficultyLevel * 0.02).clamp(0.08, 0.25);
  double get obstacleInterval => (2.5 - difficultyLevel * 0.15).clamp(1.0, 2.5);
  double get obstacleChance => (0.4 + difficultyLevel * 0.05).clamp(0.4, 0.85);
  double get floatingPlatformChance => (0.3 + difficultyLevel * 0.03).clamp(0.3, 0.5);

  // Sky gradient colors for background
  static const Color skyTop = Color(0xFF0A1628);
  static const Color skyBottom = Color(0xFF1B3A5C);
  static const Color groundColor = Color(0xFF2D5016);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  void startGame() {
    gameState = GameState.playing;
    score = 0;
    trashCollected = 0;
    distanceTravelled = 0;
    gameSpeed = 200.0;
    _spawnTimer = 0;
    _collectibleTimer = 0;
    _obstacleTimer = 0;
    _speedIncreaseTimer = 0;

    // Clear all game objects
    world.children.whereType<PlatformBlock>().toList().forEach((p) => p.removeFromParent());
    world.children.whereType<Collectible>().toList().forEach((c) => c.removeFromParent());
    world.children.whereType<Obstacle>().toList().forEach((o) => o.removeFromParent());
    world.children.whereType<EcoPlayer>().toList().forEach((p) => p.removeFromParent());

    // Create player
    player = EcoPlayer();
    player.position = Vector2(100, size.y * 0.65);
    world.add(player);

    // Spawn initial ground
    _spawnInitialGround();

    overlays.remove('MainMenu');
    overlays.remove('GameOver');
    overlays.add('HUD');
  }

  void _spawnInitialGround() {
    for (int i = 0; i < 8; i++) {
      final platform = PlatformBlock(
        position: Vector2(i * 120.0, size.y * 0.78),
        blockSize: Vector2(130, 40),
        isGround: true,
      );
      world.add(platform);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != GameState.playing) return;

    distanceTravelled += gameSpeed * dt;

    // Increase speed over time (faster ramp at higher levels)
    _speedIncreaseTimer += dt;
    final speedInterval = (3.0 - difficultyLevel * 0.2).clamp(1.5, 3.0);
    if (_speedIncreaseTimer > speedInterval) {
      gameSpeed += 10 + difficultyLevel * 2;
      _speedIncreaseTimer = 0;
    }

    // Spawn ground platforms
    _spawnTimer += dt;
    if (_spawnTimer > 0.45) {
      _spawnTimer = 0;
      _spawnGroundPlatform();
      if (_random.nextDouble() < floatingPlatformChance) {
        _spawnFloatingPlatform();
      }
    }

    // Spawn collectibles (trash)
    _collectibleTimer += dt;
    if (_collectibleTimer > 0.9) {
      _collectibleTimer = 0;
      if (_random.nextDouble() < 0.65) {
        _spawnCollectible();
      }
    }

    // Spawn obstacles (more frequent at higher difficulty)
    _obstacleTimer += dt;
    if (_obstacleTimer > obstacleInterval) {
      _obstacleTimer = 0;
      if (_random.nextDouble() < obstacleChance) {
        _spawnObstacle();
      }
    }

    _cleanupOffscreen();
  }

  void _spawnGroundPlatform() {
    if (_random.nextDouble() < gapChance) return; // gap in the ground

    // Platform width decreases with difficulty
    final width = (130.0 - difficultyLevel * 3).clamp(80.0, 130.0);
    final platform = PlatformBlock(
      position: Vector2(size.x + 50, size.y * 0.78),
      blockSize: Vector2(width, 40),
      isGround: true,
    );
    world.add(platform);
  }

  void _spawnFloatingPlatform() {
    // Physics: jumpForce=-440, gravity=980
    // Single jump max height ≈ 99px, double jump ≈ 198px from ground
    // Use 90px for single (safe margin), 170px for double (safe margin)
    final groundY = size.y * 0.78;

    // Choose staircase pattern based on difficulty
    final pattern = _random.nextInt(difficultyLevel >= 3 ? 4 : 3);

    switch (pattern) {
      case 0:
        // Single tier 1 platform (single jump from ground)
        _addPlatformWithTrash(size.x + 60, groundY - 90, 80 + _random.nextDouble() * 40);
        break;
      case 1:
        // Two-step staircase: tier 1 → tier 2
        _addPlatformWithTrash(size.x + 40, groundY - 90, 70 + _random.nextDouble() * 30);
        _addPlatformWithTrash(size.x + 150, groundY - 170, 70 + _random.nextDouble() * 30);
        break;
      case 2:
        // Double-jump platform (accessible from ground with double jump)
        _addPlatformWithTrash(size.x + 60, groundY - 170, 80 + _random.nextDouble() * 40);
        break;
      case 3:
        // Three-step staircase (high difficulty only)
        _addPlatformWithTrash(size.x + 20, groundY - 90, 65 + _random.nextDouble() * 25);
        _addPlatformWithTrash(size.x + 120, groundY - 170, 65 + _random.nextDouble() * 25);
        _addPlatformWithTrash(size.x + 220, groundY - 250, 65 + _random.nextDouble() * 25);
        break;
    }
  }

  void _addPlatformWithTrash(double x, double y, double w) {
    world.add(PlatformBlock(
      position: Vector2(x, y),
      blockSize: Vector2(w, 18),
      isGround: false,
    ));

    // Place trash sitting on top of the platform
    if (_random.nextDouble() < 0.75) {
      world.add(Collectible(
        position: Vector2(x + w / 2, y - 16), // directly above platform surface
        trashType: _random.nextInt(5),
      ));
    }
  }

  void _spawnCollectible() {
    // Spawn trash at reachable heights aligned to jump arcs
    final groundY = size.y * 0.78;
    final roll = _random.nextDouble();
    final double y;

    if (roll < 0.5) {
      // Just above ground (easy pickup while running)
      y = groundY - 40 - _random.nextDouble() * 20;
    } else if (roll < 0.8) {
      // Single jump height arc
      y = groundY - 70 - _random.nextDouble() * 20;
    } else {
      // Double jump height arc
      y = groundY - 150 - _random.nextDouble() * 20;
    }

    world.add(Collectible(
      position: Vector2(size.x + 50, y),
      trashType: _random.nextInt(5),
    ));
  }

  void _spawnObstacle() {
    // At higher difficulty, occasionally spawn double obstacles
    final obstacle = Obstacle(
      position: Vector2(size.x + 50, size.y * 0.78 - 30),
    );
    world.add(obstacle);

    // Double obstacle at high difficulty
    if (difficultyLevel >= 4 && _random.nextDouble() < 0.3) {
      final secondObstacle = Obstacle(
        position: Vector2(size.x + 180, size.y * 0.78 - 30),
      );
      world.add(secondObstacle);
    }
  }

  void _cleanupOffscreen() {
    world.children.whereType<PlatformBlock>().where((p) => p.position.x < -200).toList().forEach((p) => p.removeFromParent());
    world.children.whereType<Collectible>().where((c) => c.position.x < -100).toList().forEach((c) => c.removeFromParent());
    world.children.whereType<Obstacle>().where((o) => o.position.x < -100).toList().forEach((o) => o.removeFromParent());
  }

  void collectItem() {
    score += 10;
    trashCollected++;
  }

  void gameOver() {
    if (gameState != GameState.playing) return;
    gameState = GameState.gameOver;
    if (score > highScore) highScore = score;
    if (distanceTravelled > bestDistance) bestDistance = distanceTravelled;
    overlays.remove('HUD');
    overlays.add('GameOver');
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.playing) {
      player.jump();
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw sky gradient background
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [skyTop, skyBottom],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Draw stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (int i = 0; i < 30; i++) {
      final x = (i * 37.0 + distanceTravelled * 0.02) % size.x;
      final y = (i * 23.0) % (size.y * 0.5);
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.5, starPaint);
    }

    _drawMountains(canvas);

    // Draw ground fill
    final groundPaint = Paint()..color = groundColor;
    canvas.drawRect(Rect.fromLTWH(0, size.y * 0.78 + 20, size.x, size.y * 0.22), groundPaint);

    final groundDarkPaint = Paint()..color = const Color(0xFF1A3009);
    canvas.drawRect(Rect.fromLTWH(0, size.y * 0.88, size.x, size.y * 0.12), groundDarkPaint);

    super.render(canvas);
  }

  void _drawMountains(Canvas canvas) {
    final mountainPaint = Paint()..color = const Color(0xFF152D4A);
    final path = Path();
    path.moveTo(0, size.y * 0.6);

    for (double x = 0; x <= size.x; x += 80) {
      final offset = (x + distanceTravelled * 0.05) % 400;
      final height = 30 + sin(offset * 0.02) * 40 + cos(offset * 0.03) * 20;
      path.lineTo(x, size.y * 0.6 - height);
    }
    path.lineTo(size.x, size.y * 0.78);
    path.lineTo(0, size.y * 0.78);
    path.close();
    canvas.drawPath(path, mountainPaint);

    final mountain2Paint = Paint()..color = const Color(0xFF1A3A5A);
    final path2 = Path();
    path2.moveTo(0, size.y * 0.65);

    for (double x = 0; x <= size.x; x += 60) {
      final offset = (x + distanceTravelled * 0.08) % 300;
      final height = 15 + sin(offset * 0.03) * 25 + cos(offset * 0.02) * 15;
      path2.lineTo(x, size.y * 0.65 - height);
    }
    path2.lineTo(size.x, size.y * 0.78);
    path2.lineTo(0, size.y * 0.78);
    path2.close();
    canvas.drawPath(path2, mountain2Paint);
  }

  @override
  Color backgroundColor() => skyTop;
}
