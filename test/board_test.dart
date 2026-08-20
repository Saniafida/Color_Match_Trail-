import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';

void main() {
  group('BoardController Tests', () {
    test('Create 5x5 board', () {
      final controller = BoardController(rows: 5, columns: 5);
      expect(controller.rows, 5);
      expect(controller.columns, 5);
      expect(controller.allCells.length, 25);
      
      // Verify all positions are valid and correctly indexed
      int index = 0;
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          final pos = Position(r, c);
          expect(controller.isValidPosition(pos), isTrue);
          expect(controller.positionToIndex(pos), index);
          expect(controller.indexToPosition(index), pos);
          expect(controller.getCell(pos)?.position, pos);
          index++;
        }
      }
    });

    test('Create 7x7 board and different dimensions', () {
      final controller7x7 = BoardController(rows: 7, columns: 7);
      expect(controller7x7.allCells.length, 49);

      final controller3x8 = BoardController(rows: 3, columns: 8);
      expect(controller3x8.allCells.length, 24);
      expect(controller3x8.isValidPosition(const Position(2, 7)), isTrue);
      expect(controller3x8.isValidPosition(const Position(3, 0)), isFalse);
    });

    test('Verify invalid positions return false', () {
      final controller = BoardController(rows: 5, columns: 5);
      expect(controller.isValidPosition(const Position(5, 5)), isFalse);
      expect(controller.isValidPosition(const Position(5, 0)), isFalse);
      expect(controller.isValidPosition(const Position(0, 5)), isFalse);
    });

    test('Verify corner and center neighbors', () {
      final controller = BoardController(rows: 5, columns: 5);
      
      // Top-left corner (0,0) -> only DOWN and RIGHT
      final topLeftNeighbors = controller.getNeighbors(const Position(0, 0));
      expect(topLeftNeighbors.length, 2);
      expect(topLeftNeighbors.contains(const Position(1, 0)), isTrue); // DOWN
      expect(topLeftNeighbors.contains(const Position(0, 1)), isTrue); // RIGHT
      
      // Center (2,2) -> UP, DOWN, LEFT, RIGHT
      final centerNeighbors = controller.getNeighbors(const Position(2, 2));
      expect(centerNeighbors.length, 4);
      expect(centerNeighbors.contains(const Position(1, 2)), isTrue); // UP
      expect(centerNeighbors.contains(const Position(3, 2)), isTrue); // DOWN
      expect(centerNeighbors.contains(const Position(2, 1)), isTrue); // LEFT
      expect(centerNeighbors.contains(const Position(2, 3)), isTrue); // RIGHT
      
      // Bottom-right corner (4,4) -> only UP and LEFT
      final bottomRightNeighbors = controller.getNeighbors(const Position(4, 4));
      expect(bottomRightNeighbors.length, 2);
      expect(bottomRightNeighbors.contains(const Position(3, 4)), isTrue); // UP
      expect(bottomRightNeighbors.contains(const Position(4, 3)), isTrue); // LEFT
    });

    test('Assign a block, retrieve it, clear cell, reset board', () {
      final controller = BoardController(rows: 5, columns: 5);
      const pos = Position(2, 2);
      
      // Assign
      controller.setBlockId(pos, 'block_123');
      expect(controller.isOccupied(pos), isTrue);
      expect(controller.getBlockId(pos), 'block_123');
      expect(controller.findPositionOfBlock('block_123'), pos);
      expect(controller.hasBlock('block_123'), isTrue);
      
      // Occupancy
      expect(controller.occupiedCellCount, 1);
      expect(controller.emptyCellCount, 24);
      
      // Clear
      controller.clearCell(pos);
      expect(controller.isOccupied(pos), isFalse);
      expect(controller.getBlockId(pos), isNull);
      
      // Reset
      controller.setBlockId(pos, 'block_456');
      expect(controller.occupiedCellCount, 1);
      controller.reset();
      expect(controller.occupiedCellCount, 0);
      expect(controller.emptyCellCount, 25);
    });
    
    test('Board validation works', () {
      final controller = BoardController(rows: 7, columns: 7);
      // Validates successfully without throwing
      expect(() => controller.validateBoard(), returnsNormally);
    });
  });
}
