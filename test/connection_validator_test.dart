import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/blocks/blocks.dart';
import 'package:color_match_trail/game/trail/trail.dart';

void main() {
  group('ConnectionValidator Tests', () {
    late BoardController boardController;
    late Map<String, Block> blocks;
    late ConnectionValidator validator;

    void addBlock(Position pos, BlockColor color, {bool isLocked = false, String? id, bool isBeingDestroyed = false}) {
      var block = BlockFactory.createBlock(color: color, position: pos);
      if (id != null) block = block.copyWith(id: id);
      if (isLocked) block = block.copyWith(isLocked: true);
      if (isBeingDestroyed) block = block.copyWith(isBeingDestroyed: true);
      
      blocks[block.id] = block;
      boardController.setBlockId(pos, block.id);
    }

    setUp(() {
      boardController = BoardController(rows: 5, columns: 5);
      blocks = {};
      
      // We will define specific blocks needed for the tests
      // R0: G G G G G
      // R1: G G G R G
      // R2: G G G G G
      
      for (int c = 0; c < 5; c++) {
        addBlock(Position(0, c), BlockColor.green);
      }
      for (int c = 0; c < 5; c++) {
        addBlock(Position(1, c), c == 3 ? BlockColor.red : BlockColor.green);
      }
      for (int c = 0; c < 5; c++) {
        addBlock(Position(2, c), BlockColor.green);
      }

      validator = ConnectionValidator(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        minimumConnectionLength: 3,
      );
    });

    Trail buildTrail(List<Position> posList) {
      final ids = posList.map((p) => boardController.getBlockId(p)!).toList();
      return Trail(
        positions: posList,
        blockIds: ids,
        color: blocks[ids.first]!.color,
      );
    }

    test('TEST 1: Empty trail -> invalid', () {
      final result = validator.validate(const Trail(positions: [], blockIds: []));
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.emptyTrail);
    });

    test('TEST 2: 1 block -> insufficient', () {
      final trail = buildTrail([const Position(0, 0)]);
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.length, 1);
      expect(result.invalidReason, InvalidConnectionReason.insufficientLength);
    });

    test('TEST 3: 2 same-color adjacent blocks -> insufficient', () {
      final trail = buildTrail([const Position(0, 0), const Position(0, 1)]);
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.length, 2);
      expect(result.invalidReason, InvalidConnectionReason.insufficientLength);
    });

    test('TEST 4: 3 same-color adjacent blocks -> valid normal', () {
      final trail = buildTrail([const Position(0, 0), const Position(0, 1), const Position(0, 2)]);
      final result = validator.validate(trail);
      expect(result.isValid, isTrue);
      expect(result.length, 3);
      expect(result.connectionType, ConnectionType.normal);
    });

    test('TEST 5: 4 same-color adjacent blocks -> valid normal', () {
      final trail = buildTrail([const Position(0, 0), const Position(0, 1), const Position(0, 2), const Position(0, 3)]);
      final result = validator.validate(trail);
      expect(result.isValid, isTrue);
      expect(result.length, 4);
      expect(result.connectionType, ConnectionType.normal);
    });

    test('TEST 6 & 7: 5 and 6 same-color adjacent blocks -> valid large', () {
      final trail5 = buildTrail([const Position(0, 0), const Position(0, 1), const Position(0, 2), const Position(0, 3), const Position(0, 4)]);
      final result5 = validator.validate(trail5);
      expect(result5.isValid, isTrue);
      expect(result5.length, 5);
      expect(result5.connectionType, ConnectionType.large);

      final trail6 = buildTrail([
        const Position(0, 0), const Position(0, 1), const Position(0, 2),
        const Position(0, 3), const Position(0, 4), const Position(1, 4)
      ]);
      final result6 = validator.validate(trail6);
      expect(result6.isValid, isTrue);
      expect(result6.length, 6);
      expect(result6.connectionType, ConnectionType.large);
    });

    test('TEST 8: 7 same-color adjacent blocks -> valid mega', () {
      final trail7 = buildTrail([
        const Position(0, 0), const Position(0, 1), const Position(0, 2),
        const Position(0, 3), const Position(0, 4), const Position(1, 4), const Position(2, 4)
      ]);
      final result7 = validator.validate(trail7);
      expect(result7.isValid, isTrue);
      expect(result7.length, 7);
      expect(result7.connectionType, ConnectionType.mega);
      expect(result7.specialCreationHint, SpecialCreationType.megaSpecial);
    });

    test('TEST 9: Different color -> invalid', () {
      // (1,3) is Red, others are Green
      final trail = buildTrail([const Position(1, 1), const Position(1, 2), const Position(1, 3)]);
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.differentColor);
    });

    test('TEST 10: Diagonal connection -> invalid', () {
      final trail = buildTrail([const Position(0, 0), const Position(0, 1), const Position(1, 2)]);
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.nonAdjacent);
    });

    test('TEST 11: Non-adjacent connection -> invalid', () {
      final trail = buildTrail([const Position(0, 0), const Position(0, 1), const Position(0, 3)]);
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.nonAdjacent);
    });

    test('TEST 12: Duplicate block ID -> invalid', () {
      final p0 = const Position(0, 0);
      final p1 = const Position(0, 1);
      final id0 = boardController.getBlockId(p0)!;
      final id1 = boardController.getBlockId(p1)!;
      final trail = Trail(
        positions: [p0, p1, const Position(0, 2)],
        blockIds: [id0, id1, id0], // duplicate ID
        color: BlockColor.green,
      );
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.duplicateBlock);
    });

    test('TEST 13: Duplicate position -> invalid', () {
      final p0 = const Position(0, 0);
      final p1 = const Position(0, 1);
      final id0 = boardController.getBlockId(p0)!;
      final id1 = boardController.getBlockId(p1)!;
      final id2 = boardController.getBlockId(const Position(0, 2))!;
      final trail = Trail(
        positions: [p0, p1, p0], // duplicate pos
        blockIds: [id0, id1, id2],
        color: BlockColor.green,
      );
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.duplicatePosition);
    });

    test('TEST 14: Invalid board position -> invalid', () {
      final p0 = const Position(0, 0);
      final p1 = const Position(0, 1);
      final pOutside = const Position(5, 5);
      final id0 = boardController.getBlockId(p0)!;
      final id1 = boardController.getBlockId(p1)!;
      final trail = Trail(
        positions: [p0, p1, pOutside],
        blockIds: [id0, id1, 'some_id'],
        color: BlockColor.green,
      );
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.invalidPosition);
    });

    test('TEST 15: Inactive (beingDestroyed) block -> invalid', () {
      final p2 = const Position(0, 2);
      final id2 = boardController.getBlockId(p2)!;
      blocks[id2] = blocks[id2]!.copyWith(isBeingDestroyed: true);

      final trail = buildTrail([const Position(0, 0), const Position(0, 1), p2]);
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.inactiveBlock);
    });

    test('TEST 16: Locked block -> invalid', () {
      final p2 = const Position(0, 2);
      final id2 = boardController.getBlockId(p2)!;
      blocks[id2] = blocks[id2]!.copyWith(isLocked: true);

      final trail = buildTrail([const Position(0, 0), const Position(0, 1), p2]);
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.invalidReason, InvalidConnectionReason.lockedBlock);
    });

    test('TEST 17: Backtracking-generated final trail -> validate final correctly', () {
      final trail = buildTrail([const Position(0, 0), const Position(0, 1)]);
      final result = validator.validate(trail);
      expect(result.isValid, isFalse);
      expect(result.length, 2);
    });

    test('TEST 18: Accidental A -> B -> A -> not a mega/special loop', () {
      final trail = buildTrail([const Position(0, 0), const Position(0, 1), const Position(0, 2)]);
      final result = validator.validate(trail);
      expect(result.isClosedLoop, isFalse);
    });
  });
}
