import '../../models/booster.dart';
import '../../models/models.dart';
import '../board/board.dart';
import 'booster_combination_definition.dart';
import 'dart:math';

class BoosterCombinationManager {
  static Set<Position> executeCombinationEffect(
    CombinationResultEffect effect,
    Position targetPos,
    BoardController boardController,
    Block? Function(String) getBlock,
  ) {
    final Set<Position> positions = {};
    
    switch (effect) {
      case CombinationResultEffect.crossBlast:
        // Clear row and column
        for (int c = 0; c < boardController.columns; c++) {
          positions.add(Position(targetPos.row, c));
        }
        for (int r = 0; r < boardController.rows; r++) {
          positions.add(Position(r, targetPos.column));
        }
        break;
        
      case CombinationResultEffect.crossAndArea:
        // Clear row and column PLUS 3x3 area
        for (int c = 0; c < boardController.columns; c++) {
          positions.add(Position(targetPos.row, c));
        }
        for (int r = 0; r < boardController.rows; r++) {
          positions.add(Position(r, targetPos.column));
        }
        for (int r = max(0, targetPos.row - 1); r <= min(boardController.rows - 1, targetPos.row + 1); r++) {
          for (int c = max(0, targetPos.column - 1); c <= min(boardController.columns - 1, targetPos.column + 1); c++) {
            positions.add(Position(r, c));
          }
        }
        break;
        
      case CombinationResultEffect.largeAreaBlast:
        // Clear a 5x5 area
        for (int r = max(0, targetPos.row - 2); r <= min(boardController.rows - 1, targetPos.row + 2); r++) {
          for (int c = max(0, targetPos.column - 2); c <= min(boardController.columns - 1, targetPos.column + 2); c++) {
            positions.add(Position(r, c));
          }
        }
        break;
        
      case CombinationResultEffect.boardClearColor:
        // Clear two random colors, or all blocks of a specific color, but for simplicity, let's clear the entire board!
        // The prompt says "Color Bomb + Color Bomb = boardClearColor"
        for (int r = 0; r < boardController.rows; r++) {
          for (int c = 0; c < boardController.columns; c++) {
            positions.add(Position(r, c));
          }
        }
        break;
        
      case CombinationResultEffect.colorLineBlast:
      case CombinationResultEffect.colorAreaBlast:
        // For color combinations, we find all blocks of the target color,
        // and for each one, we apply the secondary effect!
        final targetBlockId = boardController.getBlockId(targetPos);
        if (targetBlockId == null) return {};
        
        final block = getBlock(targetBlockId);
        if (block == null || block.isLocked) return {};
        
        final targetColor = block.color;
        
        // Find all blocks of target color
        final List<Position> colorPositions = [];
        for (int r = 0; r < boardController.rows; r++) {
          for (int c = 0; c < boardController.columns; c++) {
            final pos = Position(r, c);
            final id = boardController.getBlockId(pos);
            if (id != null) {
              final b = getBlock(id);
              if (b != null && b.color == targetColor) {
                colorPositions.add(pos);
              }
            }
          }
        }
        
        // Apply effect at each position
        for (final pos in colorPositions) {
          if (effect == CombinationResultEffect.colorLineBlast) {
            // Add cross blast at each position
            for (int i = 0; i < boardController.columns; i++) {
              positions.add(Position(pos.row, i));
            }
            for (int i = 0; i < boardController.rows; i++) {
              positions.add(Position(i, pos.column));
            }
          } else {
            // Add 3x3 area at each position
            for (int r = max(0, pos.row - 1); r <= min(boardController.rows - 1, pos.row + 1); r++) {
              for (int c = max(0, pos.column - 1); c <= min(boardController.columns - 1, pos.column + 1); c++) {
                positions.add(Position(r, c));
              }
            }
          }
        }
        break;
        
      case CombinationResultEffect.unknown:
        break;
    }
    
    // Filter to only valid blocks on the board
    final Set<Position> validPositions = {};
    for (final pos in positions) {
      if (boardController.getBlockId(pos) != null) {
        validPositions.add(pos);
      }
    }
    
    return validPositions;
  }
}
