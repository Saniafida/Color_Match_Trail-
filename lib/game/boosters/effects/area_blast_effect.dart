import '../../../models/models.dart';
import '../../board/board.dart';
import 'dart:math';

class AreaBlastEffect {
  static Set<Position> getAffectedPositions(
    Position targetPos,
    BoardController boardController,
  ) {
    final Set<Position> positions = {};
    
    // Clear a 3x3 area around the target
    for (int r = max(0, targetPos.row - 1); r <= min(boardController.rows - 1, targetPos.row + 1); r++) {
      for (int c = max(0, targetPos.column - 1); c <= min(boardController.columns - 1, targetPos.column + 1); c++) {
        final pos = Position(r, c);
        final id = boardController.getBlockId(pos);
        if (id != null) {
          positions.add(pos);
        }
      }
    }
    
    return positions;
  }
}
