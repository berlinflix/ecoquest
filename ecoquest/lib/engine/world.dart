/// Dynamic world dimensions — initialized from screen size.
///
/// Call [initWorld] before using these values.
// ── World Dimensions ──

double worldWidth = 2000;
double worldHeight = 2000;
double cellSize = 200;

/// Initialize dynamic world size based on a 3x6 grid derived from screen width.
void initWorld(double screenWidth, double screenHeight) {
  cellSize = screenWidth / 3.0; // Keep visual unit scale the same
  worldWidth = cellSize * 5.0; // 1.66 screens wide (3 * 1.66)
  worldHeight = cellSize * 8.0; // ~1.3 screens tall (6 * 1.33)
}
