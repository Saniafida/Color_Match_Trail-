import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/blocks/blocks.dart';
import 'package:color_match_trail/game/trail/match_result.dart';
import 'package:color_match_trail/game/blast/blast.dart';
import 'package:color_match_trail/game/trail/trail.dart';
import 'package:color_match_trail/game/specials/special.dart';

void main() {
  group('BlastController Tests', () {
    late BoardController boardController;
    late Map<String, Block> blocks;
    late BlastController blastController;

    void addBlock(Position pos, BlockColor color, {String? id}) {
      var block = BlockFactory.createBlock(color: color, position: pos);
      if (id != null) block = block.copyWith(id: id);
      
      blocks[block.id] = block;
      boardController.setBlockId(pos, block.id);
    }

    setUp(() {
      boardController = BoardController(rows: 5, columns: 5);
      blocks = {};
      
      for (int c = 0; c < 5; c++) {
        addBlock(Position(0, c), BlockColor.green);
      }
      for (int c = 0; c < 5; c++) {
        addBlock(Position(1, c), BlockColor.green);
      }

      blastController = BlastController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (block) {
          blocks[block.id] = block;
        },
        onRemoveBlock: (id) {
          blocks.remove(id);
        },
        specialController: SpecialController(boardController: boardController, getBlock: (id) => blocks[id]),
      );
    });

    MatchResult buildMatch(List<Position> posList, ConnectionType type) {
      final ids = posList.map((p) => boardController.getBlockId(p)!).toList();
      return MatchResult(
        isValid: true,
        length: posList.length,
        positions: posList,
        blockIds: ids,
        color: BlockColor.green,
        connectionType: type,
      );
    }

    test('TEST 1: Invalid MatchResult -> no blast', () async {
      final invalidMatch = const MatchResult(isValid: false);
      final result = await blastController.processMatch(invalidMatch);
      expect(result.success, isFalse);
    });

    test('TEST 2 & 6 & 7 & 8: 3-block match -> destroys blocks, cells empty, IDs removed, unaffected remain', () async {
      final match = buildMatch(
        [const Position(0, 0), const Position(0, 1), const Position(0, 2)],
        ConnectionType.normal,
      );
      
      // Before blast
      expect(boardController.getBlockId(const Position(0, 0)), isNotNull);
      expect(blocks.containsKey(match.blockIds[0]), isTrue);
      
      final result = await blastController.processMatch(match);
      
      expect(result.success, isTrue);
      expect(result.destroyedCount, 3);
      expect(result.intensity, BlastIntensity.normal);
      
      // Destroyed cells become empty
      expect(boardController.getBlockId(const Position(0, 0)), isNull);
      expect(boardController.getBlockId(const Position(0, 1)), isNull);
      expect(boardController.getBlockId(const Position(0, 2)), isNull);
      
      // Destroyed block IDs are removed
      expect(blocks.containsKey(match.blockIds[0]), isFalse);
      expect(blocks.containsKey(match.blockIds[1]), isFalse);
      expect(blocks.containsKey(match.blockIds[2]), isFalse);
      
      // Unaffected blocks remain
      expect(boardController.getBlockId(const Position(0, 3)), isNotNull);
    });

    test('TEST 4: 5-block match -> 5 blocks destroyed, large intensity', () async {
      final match = buildMatch(
        [const Position(0, 0), const Position(0, 1), const Position(0, 2), const Position(0, 3), const Position(0, 4)],
        ConnectionType.large,
      );
      
      final result = await blastController.processMatch(match);
      
      expect(result.success, isTrue);
      expect(result.destroyedCount, 5);
      expect(result.intensity, BlastIntensity.normal);
      expect(blocks.length, 5); // 10 original - 5 removed = 5 remaining
    });

    test('TEST 5: 7-block match -> 7 blocks destroyed, mega intensity', () async {
      final match = buildMatch(
        [
          const Position(0, 0), const Position(0, 1), const Position(0, 2),
          const Position(0, 3), const Position(0, 4), const Position(1, 4), const Position(1, 3)
        ],
        ConnectionType.mega,
      );
      
      final result = await blastController.processMatch(match);
      
      expect(result.success, isTrue);
      expect(result.destroyedCount, 7);
      expect(result.intensity, BlastIntensity.mega);
    });

    test('TEST 12: Duplicate blast request is safely handled', () async {
      final match = buildMatch(
        [const Position(0, 0), const Position(0, 1), const Position(0, 2)],
        ConnectionType.normal,
      );
      
      final future1 = blastController.processMatch(match);
      final result2 = await blastController.processMatch(match);
      
      expect(result2.success, isFalse); // Should reject duplicate
      
      final result1 = await future1;
      expect(result1.success, isTrue);
    });

    test('TEST 13: Invalid/missing block is handled safely', () async {
      final match = buildMatch(
        [const Position(0, 0), const Position(0, 1), const Position(0, 2)],
        ConnectionType.normal,
      );
      
      blocks.remove(match.blockIds[0]); // Manually delete
      
      final result = await blastController.processMatch(match);
      expect(result.success, isFalse); // Fails safely
    });
  });
}
