import '../../../models/models.dart';
import '../../board/board.dart';

class HammerEffect {
  static Set<Position> getAffectedPositions(
    Position targetPos,
    BoardController boardController,
    Block? Function(String) getBlock,
  ) {
    final targetBlockId = boardController.getBlockId(targetPos);
    if (targetBlockId == null) return {};
    
    final block = getBlock(targetBlockId);
    if (block == null || block.isLocked) return {};
    
    return {targetPos};
  }
}
