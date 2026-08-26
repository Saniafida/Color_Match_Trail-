import '../../../models/models.dart';
import '../../board/board.dart';

class LineBlastEffect {
  static Set<Position> getAffectedPositions(
    Position targetPos,
    BoardController boardController,
  ) {
    final Set<Position> positions = {};
    
    // Clear entire row
    for (int c = 0; c < boardController.columns; c++) {
      final pos = Position(targetPos.row, c);
      final id = boardController.getBlockId(pos);
      if (id != null) {
        positions.add(pos);
      }
    }

    // Clear entire column
    for (int r = 0; r < boardController.rows; r++) {
      final pos = Position(r, targetPos.column);
      final id = boardController.getBlockId(pos);
      if (id != null) {
        positions.add(pos);
      }
    }
    
    return positions;
  }
}
