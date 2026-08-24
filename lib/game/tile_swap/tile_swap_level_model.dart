import '../../models/models.dart';

/// Special tile types in Tile Swap
enum TileSpecialType {
  none,
  lineHorizontal,
  lineVertical,
  colorBomb,
}

/// A cell in Tile Swap grid holding its color and optional special power
class TileSwapCell {
  final BlockColor color;
  final TileSpecialType special;

  const TileSwapCell({
    required this.color,
    this.special = TileSpecialType.none,
  });

  TileSwapCell copyWith({
    BlockColor? color,
    TileSpecialType? special,
  }) {
    return TileSwapCell(
      color: color ?? this.color,
      special: special ?? this.special,
    );
  }
}

/// Level definition for Tile Swap mini-game
class TileSwapLevel {
  final int levelNumber;
  final int moves;
  final int columns;
  final int rows;
  final List<BlockColor> activeColors;
  final Map<BlockColor, int> targetRequirements;
  final List<List<BlockColor?>>? initialGrid;
  final int star1Score;
  final int star2Score;
  final int star3Score;

  const TileSwapLevel({
    required this.levelNumber,
    required this.moves,
    this.columns = 7,
    this.rows = 7,
    required this.activeColors,
    required this.targetRequirements,
    this.initialGrid,
    required this.star1Score,
    required this.star2Score,
    required this.star3Score,
  });

  int get goalTotal => targetRequirements.values.fold(0, (sum, val) => sum + val);
}
