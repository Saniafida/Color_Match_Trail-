import 'dart:collection';
import '../../models/models.dart';
import '../board/board.dart';
import '../trail/match_result.dart';

typedef BlockLookup = Block? Function(String blockId);

class BoardMatchScanner {
  final BoardController boardController;
  final BlockLookup getBlock;
  final int minimumConnectionLength;

  BoardMatchScanner({
    required this.boardController,
    required this.getBlock,
    this.minimumConnectionLength = 3,
  });

  List<MatchResult> scan() {
    final List<MatchResult> results = [];
    final Set<String> visitedIds = {};
    
    // Scan every cell
    for (int r = 0; r < boardController.rows; r++) {
      for (int c = 0; c < boardController.columns; c++) {
        final pos = Position(r, c);
        final startBlockId = boardController.getBlockId(pos);
        
        if (startBlockId == null || visitedIds.contains(startBlockId)) {
          continue; // Empty or already processed
        }
        
        final startBlock = getBlock(startBlockId);
        if (startBlock == null || !startBlock.isActive || startBlock.isBeingDestroyed) {
          continue;
        }

        // BFS to find connected group of same color
        final targetColor = startBlock.color;
        final List<Position> groupPositions = [];
        final List<String> groupIds = [];
        final Queue<Position> queue = Queue()..add(pos);
        
        // Track local visited to prevent infinite loop within BFS
        final Set<String> localVisitedIds = {startBlockId};
        visitedIds.add(startBlockId);

        while (queue.isNotEmpty) {
          final currentPos = queue.removeFirst();
          final currentBlockId = boardController.getBlockId(currentPos)!;
          
          groupPositions.add(currentPos);
          groupIds.add(currentBlockId);

          // Check orthogonal neighbors
          final neighbors = boardController.getNeighbors(currentPos);
          for (final nPos in neighbors) {
            final nBlockId = boardController.getBlockId(nPos);
            if (nBlockId != null && !localVisitedIds.contains(nBlockId) && !visitedIds.contains(nBlockId)) {
              final nBlock = getBlock(nBlockId);
              if (nBlock != null && nBlock.isActive && !nBlock.isBeingDestroyed && nBlock.color == targetColor) {
                localVisitedIds.add(nBlockId);
                visitedIds.add(nBlockId);
                queue.add(nPos);
              }
            }
          }
        }

        // Check if group meets minimum size
        if (groupIds.length >= minimumConnectionLength) {
          ConnectionType type = ConnectionType.normal;
          if (groupIds.length >= 7) {
            type = ConnectionType.mega;
          } else if (groupIds.length >= 5) {
            type = ConnectionType.large;
          }

          results.add(MatchResult(
            isValid: true,
            length: groupIds.length,
            positions: groupPositions,
            blockIds: groupIds,
            color: targetColor,
            connectionType: type,
          ));
        }
      }
    }

    return results;
  }
}
