import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../board/board.dart';
import '../blocks/block_factory.dart';
import 'gravity_result.dart';

typedef BlockLookup = Block? Function(String blockId);
typedef BlockUpdater = void Function(Block block);
typedef BlockCreator = void Function(Block block);

class GravityController extends ChangeNotifier {
  final BoardController boardController;
  final BlockLookup getBlock;
  final BlockUpdater onUpdateBlock;
  final BlockCreator onCreateBlock;
  
  bool _isProcessing = false;
  bool get inputLocked => _isProcessing;

  GravityController({
    required this.boardController,
    required this.getBlock,
    required this.onUpdateBlock,
    required this.onCreateBlock,
  });

  Future<GravityResult> applyGravity(List<BlockColor> allowedColors) async {
    if (_isProcessing) {
      return const GravityResult();
    }
    
    _isProcessing = true;
    notifyListeners();

    final int rows = boardController.rows;
    final int columns = boardController.columns;
    
    int emptyCellsBefore = boardController.emptyCellCount;
    
    final List<GravityMove> moves = [];
    final List<SpawnedBlock> spawns = [];

    // Process column by column independently
    for (int col = 0; col < columns; col++) {
      // Target row where the next valid block should land, packing towards the bottom
      int targetRow = rows - 1;
      
      for (int row = rows - 1; row >= 0; row--) {
        final pos = Position(row, col);
        final blockId = boardController.getBlockId(pos);
        
        if (blockId != null) {
          // A block is present
          if (row < targetRow) {
            // It needs to move down
            final toPos = Position(targetRow, col);
            final distance = targetRow - row;
            
            moves.add(GravityMove(
              blockId: blockId,
              fromPosition: pos,
              toPosition: toPos,
              distance: distance,
            ));
            
            // Move it logically on the board
            boardController.clearCell(pos);
            boardController.setBlockId(toPos, blockId);
            
            // Move it logically in the registry
            final block = getBlock(blockId);
            if (block != null) {
              onUpdateBlock(block.copyWith(position: toPos));
            }
          }
          targetRow--; // Step target up by 1
        }
      }
      
      // Spawn new blocks for the remaining target rows (the empty gap at the top)
      for (int row = targetRow; row >= 0; row--) {
        final pos = Position(row, col);
        
        final newBlock = BlockFactory.createRandomBlock(
          allowedColors: allowedColors,
          position: pos,
        );
        
        spawns.add(SpawnedBlock(
          blockId: newBlock.id,
          color: newBlock.color,
          destinationPosition: pos,
          spawnIndex: row, // Top-down offset index for spawn staggering
        ));
        
        boardController.setBlockId(pos, newBlock.id);
        onCreateBlock(newBlock);
      }
    }

    if (moves.isNotEmpty || spawns.isNotEmpty) {
      // Simulate wait for fall and bounce animation duration
      await Future.delayed(const Duration(milliseconds: 350));
    }

    _isProcessing = false;
    notifyListeners();

    return GravityResult(
      movedBlocks: moves,
      spawnedBlocks: spawns,
      emptyCellsBefore: emptyCellsBefore,
      emptyCellsAfter: boardController.emptyCellCount, // Expected to be 0
      hasMovedBlocks: moves.isNotEmpty,
      hasSpawnedBlocks: spawns.isNotEmpty,
      cascadeCheckRequired: moves.isNotEmpty || spawns.isNotEmpty,
    );
  }
}
