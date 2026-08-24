import 'dart:math';
import '../../models/models.dart';
import 'tile_drop_level_model.dart';

/// Level generator for Tile Drop mini-game.
/// Supports handcrafted levels 1–10 and procedural levels up to 100.
class TileDropLevelGenerator {
  static TileDropLevel getLevel(int levelNumber) {
    if (levelNumber < 1) levelNumber = 1;

    switch (levelNumber) {
      // ══════════════════════════════════════════════
      // LEVEL 1 — Tutorial / Very Easy (2 colors, 5 cols)
      // ══════════════════════════════════════════════
      case 1:
        return TileDropLevel(
          levelNumber: 1,
          moves: 15,
          columns: 5,
          rows: 7,
          activeColors: const [BlockColor.red, BlockColor.yellow],
          targetRequirements: const {
            BlockColor.red: 6,
          },
          initialGrid: [
            // Row 0 (bottom - 5 blocks)
            [BlockColor.red, BlockColor.yellow, BlockColor.red, BlockColor.yellow, BlockColor.red],
            // Row 1 (5 blocks - total 10 initial blocks)
            [BlockColor.yellow, BlockColor.red, BlockColor.yellow, BlockColor.red, BlockColor.yellow],
            // Rows 2-6
            List.filled(5, null),
            List.filled(5, null),
            List.filled(5, null),
            List.filled(5, null),
            List.filled(5, null),
          ],
          star1Score: 300,
          star2Score: 600,
          star3Score: 1000,
        );

      // ══════════════════════════════════════════════
      // LEVEL 2 — Very Easy (2 colors, 6 cols)
      // ══════════════════════════════════════════════
      case 2:
        return TileDropLevel(
          levelNumber: 2,
          moves: 18,
          columns: 6,
          rows: 8,
          activeColors: const [BlockColor.red, BlockColor.yellow],
          targetRequirements: const {
            BlockColor.red: 8,
            BlockColor.yellow: 6,
          },
          initialGrid: [
            // Row 0 (bottom - 6 blocks)
            [BlockColor.red, BlockColor.yellow, BlockColor.red, BlockColor.yellow, BlockColor.red, BlockColor.yellow],
            // Row 1 (6 blocks - total 12 initial blocks)
            [BlockColor.yellow, BlockColor.red, BlockColor.yellow, BlockColor.red, BlockColor.yellow, BlockColor.red],
            // Rows 2-7
            List.filled(6, null),
            List.filled(6, null),
            List.filled(6, null),
            List.filled(6, null),
            List.filled(6, null),
            List.filled(6, null),
          ],
          star1Score: 500,
          star2Score: 900,
          star3Score: 1400,
        );

      // ══════════════════════════════════════════════
      // LEVEL 3 — Easy (3 colors, 6 cols)
      // ══════════════════════════════════════════════
      case 3:
        return TileDropLevel(
          levelNumber: 3,
          moves: 20,
          columns: 6,
          rows: 8,
          activeColors: const [BlockColor.red, BlockColor.yellow, BlockColor.blue],
          targetRequirements: const {
            BlockColor.red: 8,
            BlockColor.yellow: 8,
            BlockColor.blue: 6,
          },
          initialGrid: [
            // Row 0 (bottom - 6 blocks)
            [BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.red, BlockColor.yellow, BlockColor.blue],
            // Row 1 (6 blocks - total 12 initial blocks)
            [BlockColor.blue, BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.red, BlockColor.yellow],
            // Rows 2-7
            List.filled(6, null),
            List.filled(6, null),
            List.filled(6, null),
            List.filled(6, null),
            List.filled(6, null),
            List.filled(6, null),
          ],
          star1Score: 700,
          star2Score: 1200,
          star3Score: 1800,
        );

      // ══════════════════════════════════════════════
      // LEVEL 4 — Easy (3 colors, 7 cols)
      // ══════════════════════════════════════════════
      case 4:
        return TileDropLevel(
          levelNumber: 4,
          moves: 22,
          columns: 7,
          rows: 8,
          activeColors: const [BlockColor.red, BlockColor.yellow, BlockColor.blue],
          targetRequirements: const {
            BlockColor.red: 10,
            BlockColor.yellow: 8,
            BlockColor.blue: 8,
          },
          initialGrid: [
            // Row 0 (7 blocks)
            [BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.red],
            // Row 1 (5 blocks - total 12 initial blocks)
            [BlockColor.blue, BlockColor.red, BlockColor.yellow, null, BlockColor.blue, BlockColor.red, BlockColor.yellow],
            // Rows 2-7
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
          ],
          star1Score: 900,
          star2Score: 1500,
          star3Score: 2200,
        );

      // ══════════════════════════════════════════════
      // LEVEL 5 — Easy-Medium (3 colors, 7 cols)
      // ══════════════════════════════════════════════
      case 5:
        return TileDropLevel(
          levelNumber: 5,
          moves: 24,
          columns: 7,
          rows: 8,
          activeColors: const [BlockColor.red, BlockColor.yellow, BlockColor.blue],
          targetRequirements: const {
            BlockColor.red: 12,
            BlockColor.yellow: 10,
            BlockColor.blue: 10,
          },
          initialGrid: [
            // Row 0
            [BlockColor.blue, BlockColor.red, BlockColor.red, BlockColor.yellow, BlockColor.yellow, BlockColor.blue, BlockColor.blue],
            // Row 1
            [BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.red, BlockColor.blue, BlockColor.yellow, BlockColor.red],
            // Row 2
            [null, BlockColor.red, null, null, null, BlockColor.blue, null],
            // Rows 3-7
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
          ],
          star1Score: 1100,
          star2Score: 1800,
          star3Score: 2600,
        );

      // ══════════════════════════════════════════════
      // LEVEL 6 — Medium (4 colors, 7 cols)
      // ══════════════════════════════════════════════
      case 6:
        return TileDropLevel(
          levelNumber: 6,
          moves: 25,
          columns: 7,
          rows: 8,
          activeColors: const [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.green,
          ],
          targetRequirements: const {
            BlockColor.red: 10,
            BlockColor.yellow: 10,
            BlockColor.green: 8,
          },
          initialGrid: [
            // Row 0
            [BlockColor.green, BlockColor.green, BlockColor.red, BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.blue],
            // Row 1
            [BlockColor.red, BlockColor.yellow, BlockColor.green, BlockColor.yellow, BlockColor.red, BlockColor.green, BlockColor.yellow],
            // Rows 2-7
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
          ],
          star1Score: 1200,
          star2Score: 2000,
          star3Score: 3000,
        );

      // ══════════════════════════════════════════════
      // LEVEL 7 — Medium
      // ══════════════════════════════════════════════
      case 7:
        return TileDropLevel(
          levelNumber: 7,
          moves: 26,
          columns: 7,
          rows: 8,
          activeColors: const [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.green,
          ],
          targetRequirements: const {
            BlockColor.red: 12,
            BlockColor.blue: 10,
            BlockColor.green: 10,
          },
          initialGrid: [
            [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.green, BlockColor.yellow, BlockColor.blue, BlockColor.red],
            [BlockColor.blue, BlockColor.green, BlockColor.red, null, BlockColor.red, BlockColor.yellow, BlockColor.blue],
            [BlockColor.green, null, null, null, null, null, BlockColor.yellow],
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
          ],
          star1Score: 1400,
          star2Score: 2200,
          star3Score: 3200,
        );

      // ══════════════════════════════════════════════
      // LEVEL 8 — Medium
      // ══════════════════════════════════════════════
      case 8:
        return TileDropLevel(
          levelNumber: 8,
          moves: 26,
          columns: 7,
          rows: 8,
          activeColors: const [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.green,
          ],
          targetRequirements: const {
            BlockColor.red: 12,
            BlockColor.yellow: 12,
            BlockColor.blue: 10,
            BlockColor.green: 10,
          },
          initialGrid: [
            [BlockColor.yellow, BlockColor.yellow, BlockColor.blue, BlockColor.red, BlockColor.red, BlockColor.green, BlockColor.green],
            [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.yellow, BlockColor.blue, BlockColor.red, BlockColor.yellow],
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
          ],
          star1Score: 1600,
          star2Score: 2500,
          star3Score: 3600,
        );

      // ══════════════════════════════════════════════
      // LEVEL 9 — Medium-Hard
      // ══════════════════════════════════════════════
      case 9:
        return TileDropLevel(
          levelNumber: 9,
          moves: 28,
          columns: 7,
          rows: 8,
          activeColors: const [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.green,
            BlockColor.purple,
          ],
          targetRequirements: const {
            BlockColor.red: 12,
            BlockColor.purple: 10,
            BlockColor.green: 10,
          },
          initialGrid: [
            [BlockColor.purple, BlockColor.purple, BlockColor.red, BlockColor.yellow, BlockColor.green, BlockColor.blue, BlockColor.purple],
            [BlockColor.red, BlockColor.yellow, BlockColor.green, BlockColor.purple, BlockColor.blue, BlockColor.red, BlockColor.yellow],
            [null, BlockColor.purple, null, null, null, BlockColor.green, null],
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
          ],
          star1Score: 1800,
          star2Score: 2800,
          star3Score: 4000,
        );

      // ══════════════════════════════════════════════
      // LEVEL 10 — Boss / Milestone (5 colors)
      // ══════════════════════════════════════════════
      case 10:
        return TileDropLevel(
          levelNumber: 10,
          moves: 30,
          columns: 7,
          rows: 8,
          activeColors: const [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.green,
            BlockColor.purple,
          ],
          targetRequirements: const {
            BlockColor.red: 15,
            BlockColor.purple: 12,
            BlockColor.green: 12,
            BlockColor.yellow: 10,
          },
          initialGrid: [
            [BlockColor.red, BlockColor.yellow, BlockColor.purple, BlockColor.green, BlockColor.blue, BlockColor.yellow, BlockColor.red],
            [BlockColor.purple, BlockColor.green, BlockColor.blue, BlockColor.red, BlockColor.yellow, BlockColor.purple, BlockColor.green],
            [BlockColor.yellow, null, BlockColor.red, null, BlockColor.green, null, BlockColor.blue],
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
            List.filled(7, null),
          ],
          star1Score: 2200,
          star2Score: 3500,
          star3Score: 5000,
        );

      // ══════════════════════════════════════════════
      // PROCEDURAL LEVELS 11–100
      // ══════════════════════════════════════════════
      default:
        return _generateProceduralLevel(levelNumber);
    }
  }

  static TileDropLevel _generateProceduralLevel(int lvl) {
    final rng = Random(lvl * 7919);

    // Active colors based on level tier
    final List<BlockColor> allColors = [
      BlockColor.red,
      BlockColor.yellow,
      BlockColor.blue,
      BlockColor.green,
      BlockColor.purple,
    ];

    int colorCount;
    if (lvl <= 15) {
      colorCount = 4;
    } else {
      colorCount = 5;
    }

    final activeColors = allColors.sublist(0, colorCount);

    // Target requirements (pick 2 to 4 colors to target)
    final targetCount = (lvl <= 20) ? 2 : (lvl <= 40 ? 3 : 4);
    final targetColors = List<BlockColor>.from(activeColors)..shuffle(rng);
    final selectedTargets = targetColors.take(targetCount).toList();

    final Map<BlockColor, int> requirements = {};
    for (final col in selectedTargets) {
      final base = 10 + (lvl ~/ 5) * 2;
      requirements[col] = (base + rng.nextInt(5)).clamp(10, 30);
    }

    final totalGoals = requirements.values.fold(0, (s, c) => s + c);
    final moves = (totalGoals * 0.75 + 10).round().clamp(22, 45);

    // Generate initial 12-14 bottom blocks ensuring no premature 3+ matches
    const cols = 7;
    const rows = 8;
    final grid = List.generate(rows, (_) => List<BlockColor?>.filled(cols, null));

    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < cols; c++) {
        final possible = List<BlockColor>.from(activeColors);
        if (c >= 2 && grid[r][c - 1] == grid[r][c - 2]) {
          possible.remove(grid[r][c - 1]);
        }
        if (r >= 2 && grid[r - 1][c] == grid[r - 2][c]) {
          possible.remove(grid[r - 1][c]);
        }
        grid[r][c] = possible.isNotEmpty
            ? possible[rng.nextInt(possible.length)]
            : activeColors[rng.nextInt(activeColors.length)];
      }
    }

    final star1 = totalGoals * 100;
    final star2 = (star1 * 1.6).round();
    final star3 = (star1 * 2.4).round();

    return TileDropLevel(
      levelNumber: lvl,
      moves: moves,
      columns: cols,
      rows: rows,
      activeColors: activeColors,
      targetRequirements: requirements,
      initialGrid: grid,
      star1Score: star1,
      star2Score: star2,
      star3Score: star3,
    );
  }
}
