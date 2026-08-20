import '../../models/board.dart';
import '../../models/level.dart';

class BoardValidityChecker {
  bool validate(Board board, LevelDefinition config) {
    if (board.rows != config.boardConfig.rows) return false;
    if (board.columns != config.boardConfig.columns) return false;

    // Check cells
    if (board.cells.length != board.rows * board.columns) return false;

    // Check unique positions
    final positionSet = <String>{};
    for (var cell in board.cells) {
      final posStr = '${cell.position.row},${cell.position.column}';
      if (!positionSet.add(posStr)) {
        return false; // duplicate position
      }
    }

    // Check unique block IDs and valid colors
    final idSet = <String>{};
    final allowedColors = config.colorConfig?.availableColors ?? [];

    for (var block in board.blocks.values) {
      if (!idSet.add(block.id)) {
        return false; // duplicate ID
      }
      if (allowedColors.isNotEmpty && !allowedColors.contains(block.color)) {
        return false; // invalid color
      }
    }

    return true;
  }
}
