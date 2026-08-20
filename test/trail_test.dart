import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/blocks/blocks.dart';
import 'package:color_match_trail/game/trail/trail.dart';

void main() {
  group('TrailController Tests', () {
    late BoardController boardController;
    late Map<String, Block> blocks;
    late TrailController trailController;
    late Trail? finalTrailResult;

    void addBlock(Position pos, BlockColor color) {
      final block = BlockFactory.createBlock(color: color, position: pos);
      blocks[block.id] = block;
      boardController.setBlockId(pos, block.id);
    }

    setUp(() {
      boardController = BoardController(rows: 5, columns: 5);
      blocks = {};
      finalTrailResult = null;

      addBlock(const Position(0, 0), BlockColor.green);
      addBlock(const Position(0, 1), BlockColor.green);
      addBlock(const Position(0, 2), BlockColor.red);
      addBlock(const Position(1, 0), BlockColor.green);
      addBlock(const Position(1, 1), BlockColor.blue);

      trailController = TrailController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (block) {
          blocks[block.id] = block;
        },
        onTrailCompleted: (trail) {
          finalTrailResult = trail;
        },
      );
    });

    test('Touch empty cell -> no trail', () {
      trailController.handleDragStart(const Position(2, 2));
      expect(trailController.isDragging, isFalse);
      expect(trailController.activeTrail.positions, isEmpty);
    });

    test('Touch normal block -> trail starts', () {
      trailController.handleDragStart(const Position(0, 0));
      expect(trailController.isDragging, isTrue);
      expect(trailController.activeTrail.positions.length, 1);
      expect(trailController.activeTrail.color, BlockColor.green);
      
      final blockId = boardController.getBlockId(const Position(0, 0))!;
      expect(blocks[blockId]!.isSelected, isTrue);
    });

    test('Add same-color adjacent block -> accepted', () {
      trailController.handleDragStart(const Position(0, 0));
      trailController.handleDragUpdate(const Position(0, 1));
      
      expect(trailController.activeTrail.positions.length, 2);
      final blockId2 = boardController.getBlockId(const Position(0, 1))!;
      expect(blocks[blockId2]!.isSelected, isTrue);
    });

    test('Add different-color block -> rejected', () {
      trailController.handleDragStart(const Position(0, 1)); // Green
      trailController.handleDragUpdate(const Position(0, 2)); // Red
      
      expect(trailController.activeTrail.positions.length, 1);
    });

    test('Add diagonal block -> rejected', () {
      // Overwrite (1,1) to be green to test adjacency rather than color
      addBlock(const Position(1, 1), BlockColor.green); 
      
      trailController.handleDragStart(const Position(0, 0)); // Green
      trailController.handleDragUpdate(const Position(1, 1)); // Diagonal Green
      
      expect(trailController.activeTrail.positions.length, 1);
    });

    test('Repeat same block -> no duplicate', () {
      trailController.handleDragStart(const Position(0, 0));
      trailController.handleDragUpdate(const Position(0, 0));
      expect(trailController.activeTrail.positions.length, 1);
    });

    test('Backtrack one block -> last block removed', () {
      trailController.handleDragStart(const Position(0, 0));
      trailController.handleDragUpdate(const Position(0, 1));
      expect(trailController.activeTrail.positions.length, 2);
      
      final blockId2 = boardController.getBlockId(const Position(0, 1))!;
      expect(blocks[blockId2]!.isSelected, isTrue);
      
      // Backtrack
      trailController.handleDragUpdate(const Position(0, 0));
      expect(trailController.activeTrail.positions.length, 1);
      expect(blocks[blockId2]!.isSelected, isFalse);
    });

    test('Drag outside board -> safe', () {
      trailController.handleDragStart(const Position(0, 0));
      trailController.handleDragUpdate(const Position(5, 5)); // Outside board bounds
      expect(trailController.activeTrail.positions.length, 1);
    });

    test('Cancel gesture -> trail clears', () {
      trailController.handleDragStart(const Position(0, 0));
      trailController.handleDragCancel();
      
      expect(trailController.isDragging, isFalse);
      expect(trailController.activeTrail.positions, isEmpty);
      
      final blockId = boardController.getBlockId(const Position(0, 0))!;
      expect(blocks[blockId]!.isSelected, isFalse);
    });

    test('Release -> trail result returned', () {
      trailController.handleDragStart(const Position(0, 0));
      trailController.handleDragUpdate(const Position(0, 1));
      trailController.handleDragEnd();
      
      expect(trailController.isDragging, isFalse);
      expect(finalTrailResult, isNotNull);
      expect(finalTrailResult!.positions.length, 2);
      expect(finalTrailResult!.isActive, isFalse);
      
      expect(trailController.activeTrail.positions, isEmpty);
    });
  });
}
