import 'dart:math';
import '../../models/models.dart';
import 'tile_swap_level_model.dart';

/// Level generator for Tile Swap mini-game.
/// Supports handcrafted levels 1–10 and procedural levels up to 100 on a 7x7 grid with all 5 colors.
class TileSwapLevelGenerator {
  static const List<BlockColor> _all5Colors = [
    BlockColor.red,
    BlockColor.yellow,
    BlockColor.blue,
    BlockColor.green,
    BlockColor.purple,
  ];

  static TileSwapLevel getLevel(int levelNumber) {
    if (levelNumber < 1) levelNumber = 1;

    switch (levelNumber) {
      // ══════════════════════════════════════════════
      // LEVEL 1 — Easy & Balanced (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 1:
        return TileSwapLevel(
          levelNumber: 1,
          moves: 22,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.red: 10,
            BlockColor.yellow: 10,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(101)),
          star1Score: 600,
          star2Score: 1200,
          star3Score: 1800,
        );

      // ══════════════════════════════════════════════
      // LEVEL 2 — Easy (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 2:
        return TileSwapLevel(
          levelNumber: 2,
          moves: 24,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.red: 12,
            BlockColor.blue: 12,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(202)),
          star1Score: 800,
          star2Score: 1500,
          star3Score: 2200,
        );

      // ══════════════════════════════════════════════
      // LEVEL 3 — Easy-Medium (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 3:
        return TileSwapLevel(
          levelNumber: 3,
          moves: 26,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.red: 12,
            BlockColor.yellow: 12,
            BlockColor.green: 10,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(303)),
          star1Score: 1100,
          star2Score: 1800,
          star3Score: 2600,
        );

      // ══════════════════════════════════════════════
      // LEVEL 4 — Easy-Medium (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 4:
        return TileSwapLevel(
          levelNumber: 4,
          moves: 28,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.blue: 14,
            BlockColor.green: 14,
            BlockColor.purple: 12,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(404)),
          star1Score: 1300,
          star2Score: 2100,
          star3Score: 3000,
        );

      // ══════════════════════════════════════════════
      // LEVEL 5 — Medium (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 5:
        return TileSwapLevel(
          levelNumber: 5,
          moves: 28,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.red: 15,
            BlockColor.yellow: 15,
            BlockColor.blue: 15,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(505)),
          star1Score: 1500,
          star2Score: 2400,
          star3Score: 3400,
        );

      // ══════════════════════════════════════════════
      // LEVEL 6 — Medium (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 6:
        return TileSwapLevel(
          levelNumber: 6,
          moves: 30,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.red: 16,
            BlockColor.purple: 16,
            BlockColor.green: 14,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(606)),
          star1Score: 1700,
          star2Score: 2700,
          star3Score: 3800,
        );

      // ══════════════════════════════════════════════
      // LEVEL 7 — Medium (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 7:
        return TileSwapLevel(
          levelNumber: 7,
          moves: 30,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.blue: 16,
            BlockColor.green: 16,
            BlockColor.purple: 16,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(707)),
          star1Score: 1900,
          star2Score: 2900,
          star3Score: 4100,
        );

      // ══════════════════════════════════════════════
      // LEVEL 8 — Medium-Hard (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 8:
        return TileSwapLevel(
          levelNumber: 8,
          moves: 32,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.red: 18,
            BlockColor.yellow: 18,
            BlockColor.blue: 18,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(808)),
          star1Score: 2100,
          star2Score: 3200,
          star3Score: 4500,
        );

      // ══════════════════════════════════════════════
      // LEVEL 9 — Hard (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 9:
        return TileSwapLevel(
          levelNumber: 9,
          moves: 32,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.green: 18,
            BlockColor.purple: 18,
            BlockColor.yellow: 18,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(909)),
          star1Score: 2300,
          star2Score: 3500,
          star3Score: 4800,
        );

      // ══════════════════════════════════════════════
      // LEVEL 10 — Boss Level (All 5 Colors, 7x7)
      // ══════════════════════════════════════════════
      case 10:
        return TileSwapLevel(
          levelNumber: 10,
          moves: 35,
          columns: 7,
          rows: 7,
          activeColors: _all5Colors,
          targetRequirements: const {
            BlockColor.red: 20,
            BlockColor.yellow: 20,
            BlockColor.blue: 20,
            BlockColor.green: 20,
          },
          initialGrid: _generateCleanBoard(7, 7, _all5Colors, Random(1010)),
          star1Score: 2800,
          star2Score: 4200,
          star3Score: 5800,
        );

      // ══════════════════════════════════════════════
      // PROCEDURAL LEVELS 11–100
      // ══════════════════════════════════════════════
      default:
        return _generateProceduralLevel(levelNumber);
    }
  }

  /// Generates a clean board with NO initial 3-in-a-row matches,
  /// but with guaranteed valid swap moves available.
  static List<List<BlockColor?>> _generateCleanBoard(
    int cols,
    int rows,
    List<BlockColor> colors,
    Random rng,
  ) {
    while (true) {
      final board = List.generate(
        rows,
        (_) => List<BlockColor?>.filled(cols, null),
      );

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final possible = List<BlockColor>.from(colors);

          // Avoid 3 in a row horizontally
          if (c >= 2 && board[r][c - 1] == board[r][c - 2]) {
            possible.remove(board[r][c - 1]);
          }

          // Avoid 3 in a row vertically
          if (r >= 2 && board[r - 1][c] == board[r - 2][c]) {
            possible.remove(board[r - 1][c]);
          }

          board[r][c] = possible.isNotEmpty
              ? possible[rng.nextInt(possible.length)]
              : colors[rng.nextInt(colors.length)];
        }
      }

      // Verify that at least one valid swap move exists
      if (_hasValidMove(board, cols, rows)) {
        return board;
      }
    }
  }

  /// Checks if any 2 adjacent cells can be swapped to create a 3+ match.
  static bool _hasValidMove(List<List<BlockColor?>> board, int cols, int rows) {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Test right swap
        if (c + 1 < cols) {
          _swap(board, r, c, r, c + 1);
          final hasMatch = _checkMatchAt(board, r, c, cols, rows) ||
              _checkMatchAt(board, r, c + 1, cols, rows);
          _swap(board, r, c, r, c + 1); // swap back
          if (hasMatch) return true;
        }

        // Test down swap
        if (r + 1 < rows) {
          _swap(board, r, c, r + 1, c);
          final hasMatch = _checkMatchAt(board, r, c, cols, rows) ||
              _checkMatchAt(board, r + 1, c, cols, rows);
          _swap(board, r, c, r + 1, c); // swap back
          if (hasMatch) return true;
        }
      }
    }
    return false;
  }

  static void _swap(List<List<BlockColor?>> board, int r1, int c1, int r2, int c2) {
    final temp = board[r1][c1];
    board[r1][c1] = board[r2][c2];
    board[r2][c2] = temp;
  }

  static bool _checkMatchAt(
    List<List<BlockColor?>> board,
    int r,
    int c,
    int cols,
    int rows,
  ) {
    final color = board[r][c];
    if (color == null) return false;

    // Horizontal check
    int hCount = 1;
    for (int i = c - 1; i >= 0 && board[r][i] == color; i--) {
      hCount++;
    }
    for (int i = c + 1; i < cols && board[r][i] == color; i++) {
      hCount++;
    }
    if (hCount >= 3) return true;

    // Vertical check
    int vCount = 1;
    for (int i = r - 1; i >= 0 && board[i][c] == color; i--) {
      vCount++;
    }
    for (int i = r + 1; i < rows && board[i][c] == color; i++) {
      vCount++;
    }
    return vCount >= 3;
  }

  static TileSwapLevel _generateProceduralLevel(int lvl) {
    final rng = Random(lvl * 9973);
    const activeColors = _all5Colors;

    final targetCount = (lvl <= 20) ? 2 : (lvl <= 40 ? 3 : 4);
    final targetColors = List<BlockColor>.from(activeColors)..shuffle(rng);
    final selectedTargets = targetColors.take(targetCount).toList();

    final Map<BlockColor, int> requirements = {};
    for (final col in selectedTargets) {
      final base = 12 + (lvl ~/ 5) * 2;
      requirements[col] = (base + rng.nextInt(6)).clamp(12, 35);
    }

    final totalGoals = requirements.values.fold(0, (s, c) => s + c);
    final moves = (totalGoals * 0.7 + 10).round().clamp(24, 45);

    const cols = 7;
    const rows = 7;
    final board = _generateCleanBoard(cols, rows, activeColors, rng);

    final star1 = totalGoals * 100;
    final star2 = (star1 * 1.6).round();
    final star3 = (star1 * 2.4).round();

    return TileSwapLevel(
      levelNumber: lvl,
      moves: moves,
      columns: cols,
      rows: rows,
      activeColors: activeColors,
      targetRequirements: requirements,
      initialGrid: board,
      star1Score: star1,
      star2Score: star2,
      star3Score: star3,
    );
  }
}
