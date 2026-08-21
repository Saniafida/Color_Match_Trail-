import '../../../models/models.dart';
import '../../board/board.dart';

class ShuffleEffect {
  static Future<void> execute(
    BoardController boardController,
    void Function(String, Position) onMoveBlock,
  ) async {
    final List<String> blockIds = [];
    final List<Position> positions = [];

    for (int r = 0; r < boardController.rows; r++) {
      for (int c = 0; c < boardController.columns; c++) {
        final pos = Position(r, c);
        final id = boardController.getBlockId(pos);
        if (id != null) {
          blockIds.add(id);
          positions.add(pos);
        }
      }
    }

    blockIds.shuffle();

    for (int i = 0; i < blockIds.length; i++) {
      boardController.setBlockId(positions[i], blockIds[i]);
      onMoveBlock(blockIds[i], positions[i]);
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }
}
