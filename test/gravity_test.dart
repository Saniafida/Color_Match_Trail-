import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/blocks/blocks.dart';
import 'package:color_match_trail/game/gravity/gravity.dart';

void main() {
  group('GravityController Tests', () {
    late BoardController boardController;
    late Map<String, Block> blocks;
    late GravityController gravityController;

    void addBlock(Position pos, BlockColor color, {String? id}) {
      var block = BlockFactory.createBlock(color: color, position: pos);
      if (id != null) block = block.copyWith(id: id);
      
      blocks[block.id] = block;
      boardController.setBlockId(pos, block.id);
    }

    void removeBlock(Position pos) {
      final id = boardController.getBlockId(pos);
      if (id != null) {
        boardController.clearCell(pos);
        blocks.remove(id);
      }
    }

    setUp(() {
      boardController = BoardController(rows: 5, columns: 5);
      blocks = {};
      
      // Fill board initially
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          addBlock(Position(r, c), BlockColor.green);
        }
      }

      gravityController = GravityController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (block) {
          blocks[block.id] = block;
        },
        onCreateBlock: (block) {
          blocks[block.id] = block;
        },
      );
    });

    final defaultColors = [BlockColor.red, BlockColor.green, BlockColor.blue];

    test('TEST 1: No empty cells -> no movement -> no spawning', () async {
      final result = await gravityController.applyGravity(defaultColors);
      
      expect(result.hasMovedBlocks, isFalse);
      expect(result.hasSpawnedBlocks, isFalse);
      expect(result.cascadeCheckRequired, isFalse);
      expect(result.emptyCellsBefore, 0);
      expect(result.emptyCellsAfter, 0);
    });

    test('TEST 2: One empty cell -> blocks above fall', () async {
      removeBlock(const Position(3, 0));
      final blockAboveId = boardController.getBlockId(const Position(2, 0))!;
      
      final result = await gravityController.applyGravity(defaultColors);
      
      expect(result.hasMovedBlocks, isTrue);
      expect(result.emptyCellsBefore, 1);
      
      // Check block 2,0 moved to 3,0
      final move = result.movedBlocks.firstWhere((m) => m.blockId == blockAboveId);
      expect(move.fromPosition, const Position(2, 0));
      expect(move.toPosition, const Position(3, 0));
      expect(move.distance, 1);
    });

    test('TEST 3 & 4: Multiple empty cells in same column -> order preserved', () async {
      // Col 1 initially has blocks at 0, 1, 2, 3, 4
      final idTop = boardController.getBlockId(const Position(1, 1))!;
      final idBottom = boardController.getBlockId(const Position(3, 1))!;
      
      // Remove 2, 4
      removeBlock(const Position(2, 1));
      removeBlock(const Position(4, 1));
      
      final result = await gravityController.applyGravity(defaultColors);
      
      // The bottom-most remaining is at row 3. It should fall to 4.
      // The next remaining is at row 1. It should fall to 3.
      // The top remaining is at row 0. It should fall to 2.
      final moveBottom = result.movedBlocks.firstWhere((m) => m.blockId == idBottom);
      expect(moveBottom.toPosition, const Position(4, 1));
      
      final moveTop = result.movedBlocks.firstWhere((m) => m.blockId == idTop);
      expect(moveTop.toPosition, const Position(3, 1));
      
      // Spawned 2 blocks at 0,1 and 1,1
      expect(result.spawnedBlocks.where((s) => s.destinationPosition.column == 1).length, 2);
    });

    test('TEST 5: Empty cells in different columns -> independent', () async {
      removeBlock(const Position(4, 0));
      removeBlock(const Position(4, 1));
      
      final result = await gravityController.applyGravity(defaultColors);
      
      expect(result.movedBlocks.length, 8); // 4 from col 0, 4 from col 1
      expect(result.spawnedBlocks.length, 2);
    });

    test('TEST 6: All blocks removed from a column -> entire column receives new blocks', () async {
      for (int r = 0; r < 5; r++) {
        removeBlock(Position(r, 2));
      }
      
      final result = await gravityController.applyGravity(defaultColors);
      
      expect(result.movedBlocks.isEmpty, isTrue); // Nothing left to move in that column
      expect(result.spawnedBlocks.length, 5); // 5 new spawned
    });

    test('TEST 7 & 10 & 11 & 14: Partial removal, colors correct, cascade required, no empty cells', () async {
      removeBlock(const Position(3, 4));
      removeBlock(const Position(4, 4));
      
      final result = await gravityController.applyGravity([BlockColor.red]);
      
      expect(result.spawnedBlocks.length, 2);
      expect(result.emptyCellsAfter, 0); // TEST 11
      expect(result.cascadeCheckRequired, isTrue); // TEST 14
      
      // TEST 10: all spawned blocks must be red
      expect(result.spawnedBlocks.every((s) => s.color == BlockColor.red), isTrue);
    });

    test('TEST 8 & 9: Block ID unchanged, New IDs unique', () async {
      final oldId = boardController.getBlockId(const Position(3, 3))!;
      removeBlock(const Position(4, 3));
      
      final result = await gravityController.applyGravity(defaultColors);
      
      // TEST 8
      expect(boardController.getBlockId(const Position(4, 3)), oldId); // old ID moved down
      
      // TEST 9
      final newId = result.spawnedBlocks.first.blockId;
      expect(newId != oldId, isTrue);
      expect(blocks.containsKey(newId), isTrue); // New block in registry
    });

    test('TEST 13: Blocks that don\'t move produce no movement animation', () async {
      // Remove top block
      removeBlock(const Position(0, 0));
      
      final result = await gravityController.applyGravity(defaultColors);
      
      // The bottom 4 blocks didn't move. They should NOT be in movedBlocks.
      expect(result.movedBlocks.isEmpty, isTrue);
      expect(result.spawnedBlocks.length, 1);
    });
  });
}
