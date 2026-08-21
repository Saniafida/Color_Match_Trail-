import '../../../models/models.dart';
import '../../board/board.dart';

class ColorBombEffect {
  static Set<Position> getAffectedPositions(
    Position targetPos,
    BoardController boardController,
    Block? Function(String) getBlock,
  ) {
    final targetBlockId = boardController.getBlockId(targetPos);
    if (targetBlockId == null) return {};
    
    final block = getBlock(targetBlockId);
    if (block == null || block.isLocked) return {};
    
    final targetColor = block.color;
    final Set<Position> positions = {};
    
    for (int r = 0; r < boardController.rows; r++) {
      for (int c = 0; c < boardController.columns; c++) {
        final pos = Position(r, c);
        final id = boardController.getBlockId(pos);
        if (id != null) {
          final b = getBlock(id);
          if (b != null && b.color == targetColor) {
            positions.add(pos);
          }
        }
      }
    }
    
    return positions;
  }
}
