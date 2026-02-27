import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/world.dart';
import '../models/boundary.dart';
import '../models/collectible.dart';
import '../models/enemy.dart';
import '../models/hazard.dart';
import '../models/player.dart';
import '../ui/home_screen.dart';
import '../ui/joystick.dart';

/// The main game screen — full-screen 2D canvas with game loop, joystick,
/// score HUD, enemy spawner, health system, and win/game-over states.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastFrameTime = Duration.zero;
  final Random _rng = Random();

  static const double _baseSpeed = 200;

  static const int maxTotalEnemies = 15;
  int totalEnemiesSpawned = 0;

  late Player _player;
  late List<Collectible> _collectibles;
  late List<Tree> _trees;
  late Hazard _hazard;
  List<Enemy> _activeEnemies = [];
  double _spawnTimer = 0;

  // Preloaded enemy sprite images
  ui.Image? _catSprite;
  ui.Image? _dogSprite;
  ui.Image? _h1Sprite;
  ui.Image? _h2Sprite;

  // Preloaded tree sprite images
  ui.Image? _t1Sprite;
  ui.Image? _t2Sprite;

  // Preloaded litter sprite images
  ui.Image? _l1Sprite;
  ui.Image? _l2Sprite;
  ui.Image? _l3Sprite;
  ui.Image? _l4Sprite;

  // Currency HUD icon
  ui.Image? _currencySprite;

  int trashCurrency = 0;
  bool _isPaused = false;
  bool _isAtHome = false;
  bool _hasWon = false;
  bool _isGameOver = false;
  bool _worldInitialized = false;
  bool _isLoadingWorld = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _initGameWorld(Size screenSize) async {
    if (_isLoadingWorld) return;
    _isLoadingWorld = true;
    if (screenSize.width <= 0 || screenSize.height <= 0) {
      // Defer initialization if the framework provides a 0-size rect.
      _isLoadingWorld = false;
      return;
    }
    initWorld(screenSize.width, screenSize.height);
    if (worldWidth <= 0 || worldHeight <= 0) return;

    _player = Player(x: worldWidth / 2, y: worldHeight / 2);
    _collectibles = _spawnCollectibles();
    _hazard = Hazard(x: worldWidth / 2, y: worldHeight / 2 - 80);
    _activeEnemies = [];
    _spawnTimer = 0;
    totalEnemiesSpawned = 0;
    trashCurrency = 0;

    // Load ALL sprites before spawning anything, so no enemy gets a null sprite.
    final results = await Future.wait([
      _loadImage('assets/images/player.png'), // 0
      _loadImage('assets/images/cat.png'),    // 1
      _loadImage('assets/images/dog.png'),    // 2
      _loadImage('assets/images/h1.png'),     // 3
      _loadImage('assets/images/h2.png'),     // 4
      _loadImage('assets/images/t1.png'),     // 5
      _loadImage('assets/images/t2.png'),     // 6
      _loadImage('assets/images/l1.png'),     // 7
      _loadImage('assets/images/l2.png'),     // 8
      _loadImage('assets/images/l3.png'),     // 9
      _loadImage('assets/images/l4.png'),     // 10
      _loadImage('assets/images/currency.png'), // 11
    ]);

    if (!mounted) return;

    _player.spriteImage = results[0];
    _catSprite = results[1];
    _dogSprite = results[2];
    _h1Sprite = results[3];
    _h2Sprite = results[4];
    _t1Sprite = results[5];
    _t2Sprite = results[6];
    _l1Sprite = results[7];
    _l2Sprite = results[8];
    _l3Sprite = results[9];
    _l4Sprite = results[10];
    _currencySprite = results[11];

    // Now that tree sprites are loaded, regenerate trees so they all get sprites
    _trees = _generatePerimeterTrees();

    // Spawn initial horde — sprites are guaranteed to be loaded now
    for (int i = 0; i < 7; i++) {
      _trySpawnEnemy();
    }

    setState(() {
      _worldInitialized = true;
    });
  }

  /// Loads a Flutter asset image into a dart:ui Image for canvas rendering.
  Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load('packages/ecoquest/$assetPath');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  List<Collectible> _spawnCollectibles() {
    return []; // Map starts strictly empty of collectibles
  }

  List<Tree> _generatePerimeterTrees() {
    final List<Tree> trees = [];
    const double r = 30; // Tree radius (must match Tree default)
    const double spacing = r * 2.0; // Edge-to-edge contact, no gap

    // Helper to pick a random tree sprite
    ui.Image? _randomTreeSprite() => _rng.nextBool() ? _t1Sprite : _t2Sprite;

    // Top and Bottom rows — inset by radius so full circle is visible
    for (double x = 0; x <= worldWidth; x += spacing) {
      trees.add(Tree(x: x, y: r, sprite: _randomTreeSprite()));
      trees.add(Tree(x: x, y: worldHeight - r, sprite: _randomTreeSprite()));
    }
    // Left and Right columns — inset by radius, avoid corners already covered
    for (double y = spacing; y < worldHeight; y += spacing) {
      trees.add(Tree(x: r, y: y, sprite: _randomTreeSprite()));
      trees.add(Tree(x: worldWidth - r, y: y, sprite: _randomTreeSprite()));
    }

    return trees;
  }

  /// Attempt to spawn a random enemy type.
  void _trySpawnEnemy() {
    if (totalEnemiesSpawned >= maxTotalEnemies) return;

    // Randomly pick a type.
    final EnemyType chosenType = _rng.nextBool()
        ? EnemyType.human
        : EnemyType.animal;

    // Random position inside the tree perimeter.
    const double margin = 70;
    final double ex = margin + _rng.nextDouble() * (worldWidth - margin * 2);
    final double ey = margin + _rng.nextDouble() * (worldHeight - margin * 2);

    _activeEnemies.add(
      Enemy(x: ex, y: ey, type: chosenType)
        ..sprite = chosenType == EnemyType.animal
            ? (_rng.nextBool() ? _catSprite : _dogSprite)
            : (_rng.nextBool() ? _h1Sprite : _h2Sprite),
    );
    totalEnemiesSpawned++;
  }

  void _onTick(Duration elapsed) {
    if (!_worldInitialized) return;

    final double dt = (_lastFrameTime == Duration.zero)
        ? 0
        : (elapsed - _lastFrameTime).inMicroseconds / 1e6;
    _lastFrameTime = elapsed;

    _update(dt);
    setState(() {});
  }

  void _update(double dt) {
    if (_hasWon || _isGameOver || _isPaused || _isAtHome) return;

    _player.update(dt);
    _hazard.update(dt);

    // ── Global Spawner (every 8s up to map cap, max 7 living) ──
    if (_activeEnemies.length < 7 && totalEnemiesSpawned < maxTotalEnemies) {
      _spawnTimer += dt;
      if (_spawnTimer >= 8.0) {
        _spawnTimer = 0;
        _trySpawnEnemy();
      }
    } else if (_activeEnemies.length >= 7) {
      // Keep timer at 0 when map is full, so the 8 seconds starts *after* one dies
      _spawnTimer = 0;
    }

    // ── Update enemies (backward iteration for safe removal) ──
    for (int i = _activeEnemies.length - 1; i >= 0; i--) {
      final enemy = _activeEnemies[i];
      enemy.update(dt, _player.x, _player.y, _collectibles, _activeEnemies);

      // Enemy ↔ Player collision.
      final double dx = _player.x - enemy.x;
      final double dy = _player.y - enemy.y;
      final double dist = sqrt(dx * dx + dy * dy);
      if (dist < _player.radius + enemy.radius) {
        _player.takeDamage(enemy.damageToPlayer);
      }

      // Orbital Weapon ↔ Enemy collision.
      for (final weapon in _player.activeWeapons) {
        final double wDx = weapon.x - enemy.x;
        final double wDy = weapon.y - enemy.y;
        final double wDist = sqrt(wDx * wDx + wDy * wDy);

        if (wDist < weapon.hitboxRadius + enemy.radius) {
          enemy.takeDamage(weapon.damage);
        }
      }

      // Handle enemy death and drops.
      if (enemy.isDead) {
        final sprites = [_l1Sprite, _l2Sprite, _l3Sprite, _l4Sprite];
        if (enemy.type == EnemyType.human) {
          _collectibles.add(
            Collectible(x: enemy.x - 12, y: enemy.y)
              ..sprite = sprites[_rng.nextInt(4)],
          );
          _collectibles.add(
            Collectible(x: enemy.x + 12, y: enemy.y)
              ..sprite = sprites[_rng.nextInt(4)],
          );
        } else {
          _collectibles.add(
            Collectible(x: enemy.x, y: enemy.y)
              ..sprite = sprites[_rng.nextInt(4)],
          );
        }
        _activeEnemies.removeAt(i);
      }
    }

    // Assign sprite to any litter dropped by enemy litter-timer
    final _litterSprites = [_l1Sprite, _l2Sprite, _l3Sprite, _l4Sprite];
    for (final c in _collectibles) {
      if (c.sprite == null && !c.isCollected) {
        c.sprite = _litterSprites[_rng.nextInt(4)];
      }
    }

    // ── Collectible collision ──
    for (final c in _collectibles) {
      if (c.isCollected) continue;
      final double dx = _player.x - c.x;
      final double dy = _player.y - c.y;
      final double dist = sqrt(dx * dx + dy * dy);
      if (dist < _player.radius + c.radius) {
        c.isCollected = true;
        trashCurrency++;
      }
    }

    // Win check (Horde Elimination).
    if (_activeEnemies.isEmpty && _worldInitialized) {
      _hasWon = true;
    }

    // ── Hazard collision ──
    {
      final double dx = _player.x - _hazard.x;
      final double dy = _player.y - _hazard.y;
      final double dist = sqrt(dx * dx + dy * dy);
      if (dist < _player.radius + _hazard.radius) {
        _player.takeDamage(10);
      }
    }

    // ── Tree (boundary) collision — push player out ──
    for (final tree in _trees) {
      final double dx = _player.x - tree.x;
      final double dy = _player.y - tree.y;
      final double dist = sqrt(dx * dx + dy * dy);
      final double minDist = _player.radius + tree.radius;
      if (dist < minDist && dist > 0) {
        // Push player directly away from tree center
        final double overlap = minDist - dist;
        _player.x += (dx / dist) * overlap;
        _player.y += (dy / dist) * overlap;
      }
    }

    // ── Death check ──
    if (_player.currentHp <= 0) {
      _isGameOver = true;
    }
  }

  void _onJoystickDirection(Offset direction) {
    if (_hasWon || _isGameOver || _isPaused || _isAtHome) return;
    _player.vx = direction.dx * _baseSpeed;
    _player.vy = direction.dy * _baseSpeed;
  }

  void _restart() {
    setState(() {
      trashCurrency = 0;
      totalEnemiesSpawned = 0;
      _spawnTimer = 0;
      _hasWon = false;
      _isGameOver = false;
      _isPaused = false;
      _isAtHome = false;
      _player.x = worldWidth / 2;
      _player.y = worldHeight / 2;
      _player.vx = 0;
      _player.vy = 0;
      _player.currentHp = _player.maxHp;
      _player.invincibilityTimer = 0;
      _collectibles = _spawnCollectibles();
      _activeEnemies = [];
      _hazard = Hazard(x: worldWidth / 2, y: worldHeight / 2 - 80);

      // Reset weapons to default speeds (undo any in-game upgrades)
      _player.activeWeapons[0].revolutionSpeed = 4.0; // Light weapon default
      _player.activeWeapons[1].revolutionSpeed = 2.5; // Heavy weapon default

      for (int i = 0; i < 7; i++) {
        _trySpawnEnemy();
      }
      _worldInitialized = true;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Art Deco Background Helpers ──

  Widget _buildSilhouette(double width, double height, Color borderColor) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0D001A),
        border: Border(
          top: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 2),
          left: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 2),
          right: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 2),
        ),
      ),
    );
  }

  Widget _neonPalmTree({double size = 120}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Icon(
        Icons.beach_access,
        size: size * 0.8,
        color: const Color(0xFFFF00FF),
        shadows: [
          Shadow(
            color: const Color(0xFFFF00FF).withValues(alpha: 0.8),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _footerIcon(IconData icon, String label, Color color, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ── Original Upgrade Shop Button Helper ──

  Widget _neonUpgradeButton({
    required IconData icon,
    required String label,
    required String costLabel,
    required bool canAfford,
    required VoidCallback onTap,
  }) {
    const green = Color(0xFF0DF20D); // primary neon green
    final borderColor = canAfford ? green : const Color(0xFF475569); // slate-600
    final textColor = canAfford ? const Color(0xFF0F172A) : const Color(0xFF94A3B8); // slate-900 or slate-400
    final bgColor = canAfford ? green : Colors.transparent;

    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                    color: green.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$label $costLabel',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (!_worldInitialized) {
      _initGameWorld(screenSize);
    }

    return Stack(
      children: [
        // ── Main Arena Background (Voxel Grass) ──
        Positioned.fill(
          child: Container(
            color: const Color(0xFF4ADE80), // Voxel Grass Base
            child: Stack(
              children: [
                // Perspective applied to the grid and game world to keep the top-down feel
                if (_worldInitialized)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GamePainter(
                        player: _player,
                        collectibles: _collectibles,
                        trees: _trees,
                        hazard: _hazard,
                        enemies: _activeEnemies,
                        screenSize: screenSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Top UI Layer (Voxel Green Arena V2) ──
        Positioned(
          top: 24,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TRASH Counter: Pixel Art Bubble Style
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // slate-900
                  border: Border.all(color: const Color(0xFF334155), width: 4), // slate-700
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D000000), // rgba(0,0,0,0.3)
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TRASH',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B), // slate-500
                          letterSpacing: 2,
                          height: 1.0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            num.parse(trashCurrency.toStringAsFixed(0)).toString(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A), // slate-900
                              height: 1.0,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+15%',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF059669), // emerald-600
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Upgrade & Quit Buttons
              if (!_isAtHome && !_hasWon && !_isGameOver)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quit Home Button (kept for logic)
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(bottom: BorderSide(color: Color(0xFFB71C1C), width: 4)),
                        ),
                        child: const Icon(Icons.home, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // UPGRADE Button: Vibrant Neon Green
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPaused = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0DF20D), // primary green
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFF047857), width: 4), // emerald-700
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.upgrade,
                              color: Color(0xFF0F172A), // slate-900
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'UPGRADE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A), // slate-900
                                letterSpacing: -0.5,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // ── Virtual Joystick ──
        // Drawn on top of everything except overlays.
        Positioned(
          left: 40,
          top: screenSize.height * 0.65,
          child: VirtualJoystick(onDirectionChanged: _onJoystickDirection),
        ),

        // ── Win Overlay ──
        if (_hasWon)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎉 You Win!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All litter collected!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _restart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5CC),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Play Again',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Home Page',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Game Over Overlay ──
        if (_isGameOver)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '💀 Game Over',
                      style: TextStyle(
                        color: Color(0xFFF44336),
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You were defeated!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _restart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF44336),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Restart',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Home Page',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Upgrade Shop Overlay (Voxel Green Style) ──
        if (_isPaused && !_hasWon && !_isGameOver)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F172A).withValues(alpha: 0.85), // slate-900 bg
              child: Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // slate-800
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0DF20D), // primary green
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0DF20D).withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Title ──
                      Text(
                        'UPGRADE SHOP',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ── Currency ──
                      Text(
                        'Currency: $trashCurrency Trash',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4ADE80), // emerald green
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Light Weapon Button ──
                      _neonUpgradeButton(
                        icon: Icons.bolt,
                        label: 'L. WEAPON',
                        costLabel: '(15)',
                        canAfford: trashCurrency >= 15,
                        onTap: () {
                          if (trashCurrency >= 15) {
                            setState(() {
                              trashCurrency -= 15;
                              if (_player.activeWeapons.isNotEmpty) {
                                _player.activeWeapons[0].revolutionSpeed +=
                                    1.0;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Heavy Weapon Button ──
                      _neonUpgradeButton(
                        icon: Icons.shutter_speed,
                        label: 'H. WEAPON',
                        costLabel: '(20)',
                        canAfford: trashCurrency >= 20,
                        onTap: () {
                          if (trashCurrency >= 20) {
                            setState(() {
                              trashCurrency -= 20;
                              if (_player.activeWeapons.length > 1) {
                                _player.activeWeapons[1].revolutionSpeed +=
                                    0.5;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 40),

                      // ── Close Shop ──
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPaused = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF64748B), // slate-500
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'CLOSE',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8), // slate-400
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Draws the 2D game world with camera viewport.
class _GamePainter extends CustomPainter {
  final Player player;
  final List<Collectible> collectibles;
  final List<Tree> trees;
  final Hazard hazard;
  final List<Enemy> enemies;
  final Size screenSize;

  _GamePainter({
    required this.player,
    required this.collectibles,
    required this.trees,
    required this.hazard,
    required this.enemies,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double sw = screenSize.width;
    final double sh = screenSize.height;

    double maxCamX = worldWidth - sw;
    if (maxCamX < 0.0) maxCamX = 0.0;
    double maxCamY = worldHeight - sh;
    if (maxCamY < 0.0) maxCamY = 0.0;

    double camX = player.x - sw / 2;
    if (camX < 0.0) camX = 0.0;
    if (camX > maxCamX) camX = maxCamX;

    double camY = player.y - sh / 2;
    if (camY < 0.0) camY = 0.0;
    if (camY > maxCamY) camY = maxCamY;

    canvas.save();
    canvas.translate(-camX, -camY);

    // ── World boundary ──
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, worldWidth, worldHeight), borderPaint);

    // ── Trees ──
    for (final t in trees) {
      t.draw(canvas);
    }

    // ── Hazard ──
    hazard.draw(canvas);

    // ── Collectibles ──
    for (final c in collectibles) {
      c.draw(canvas);
    }

    // ── Enemies ──
    for (final e in enemies) {
      e.draw(canvas);
    }

    // ── Player ──
    player.draw(canvas);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}

// ── Background Painters & Clippers ──

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Equivalent to the .pixel-grid CSS:
    // linear-gradient(to right, rgba(0,0,0,0.05) 1px, transparent 1px)
    final Paint paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double gridSize = 40.0;
    
    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
