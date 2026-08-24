import '../../models/models.dart';

/// Represents a level configuration for the Tile Drop game.
class TileDropLevel {
  final int levelNumber;
  final int moves;
  final int columns;
  final int rows;
  final List<BlockColor> activeColors;
  final Map<BlockColor, int> targetRequirements;
  final List<List<BlockColor?>>? initialGrid; // [row][col], row 0 is bottom
  final int star1Score;
  final int star2Score;
  final int star3Score;

  const TileDropLevel({
    required this.levelNumber,
    required this.moves,
    this.columns = 7,
    this.rows = 8,
    required this.activeColors,
    required this.targetRequirements,
    this.initialGrid,
    this.star1Score = 500,
    this.star2Score = 1000,
    this.star3Score = 1500,
  });

  int get goalTotal =>
      targetRequirements.values.fold(0, (sum, count) => sum + count);
}
