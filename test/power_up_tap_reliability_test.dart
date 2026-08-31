import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/blast/blast.dart';
import 'package:color_match_trail/game/specials/special.dart';
import 'package:color_match_trail/game/specials/power_up_manager.dart';
import 'package:color_match_trail/game/boosters/booster.dart';

void main() {
  group('Power-Up & Booster Tap Reliability Tests', () {
    late BoardController boardController;
    late Map<String, Block> blocks;
    late SpecialController specialController;
    late BlastController blastController;
    late PowerUpManager powerUpManager;
    late BoosterController boosterController;

    void addBlock(Position pos, BlockColor color, {String? id, SpecialBlockType special = SpecialBlockType.none}) {
      final blockId = id ?? 'b_${pos.row}_${pos.column}';
      final block = Block(
        id: blockId,
        color: color,
        position: pos,
        specialType: special,
      );
      blocks[blockId] = block;
      boardController.setBlockId(pos, blockId);
    }

    setUp(() {
      boardController = BoardController(rows: 6, columns: 6);
      blocks = {};

      specialController = SpecialController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
      );

      blastController = BlastController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (b) => blocks[b.id] = b,
        onRemoveBlock: (id) => blocks.remove(id),
        specialController: specialController,
      );

      powerUpManager = PowerUpManager(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (b) => blocks[b.id] = b,
        onRemoveBlock: (id) => blocks.remove(id),
        specialController: specialController,
        blastController: blastController,
      );

      boosterController = BoosterController(
        boardController: boardController,
        blastController: blastController,
        getBlock: (id) => blocks[id],
        onMoveBlock: (id, pos) {
          if (blocks.containsKey(id)) {
            blocks[id] = blocks[id]!.copyWith(position: pos);
          }
        },
        specialController: specialController,
      );
    });

    test('1. Direct tap activation on Bomb destroys 3x3 area even with empty cells present', () async {
      // Setup grid with some empty cells
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          if (r == 1 && c == 1) continue; // Leave an empty space in the blast zone
          addBlock(Position(r, c), BlockColor.blue);
        }
      }

      // Add Bomb at (2, 2)
      addBlock(const Position(2, 2), BlockColor.blue, id: 'bomb_center', special: SpecialBlockType.bomb);

      final blastResult = await powerUpManager.activatePowerUpAt(const Position(2, 2));

      expect(blastResult.success, isTrue);
      // Bomb should destroy all remaining 8 blocks in the 3x3 radius without crashing on the empty cell (1, 1)
      expect(blastResult.destroyedPositions.contains(const Position(2, 2)), isTrue);
      expect(boardController.getBlockId(const Position(2, 2)), isNull);
      expect(blocks.containsKey('bomb_center'), isFalse);
    });

    test('2. Direct tap activation on Line Blast (Horizontal) clears full row with empty gaps', () async {
      for (int c = 0; c < 6; c++) {
        if (c == 3) continue; // Gap
        addBlock(Position(2, c), BlockColor.red);
      }
      addBlock(const Position(2, 0), BlockColor.red, id: 'rocket_2_0', special: SpecialBlockType.horizontalLine);

      final blastResult = await powerUpManager.activatePowerUpAt(const Position(2, 0));

      expect(blastResult.success, isTrue);
      expect(blastResult.destroyedCount, 5); // 5 blocks in row (1 was empty)
      expect(boardController.getBlockId(const Position(2, 0)), isNull);
    });

    test('3. Chain reaction: Bomb triggers adjacent Cross Blast reliably', () async {
      for (int r = 0; r < 6; r++) {
        for (int c = 0; c < 6; c++) {
          addBlock(Position(r, c), BlockColor.green);
        }
      }

      // Bomb at (2, 2)
      addBlock(const Position(2, 2), BlockColor.green, id: 'bomb_2_2', special: SpecialBlockType.bomb);
      // Cross Blast at (2, 3) inside bomb radius
      addBlock(const Position(2, 3), BlockColor.green, id: 'cross_2_3', special: SpecialBlockType.crossBlast);

      final blastResult = await powerUpManager.activatePowerUpAt(const Position(2, 2));

      expect(blastResult.success, isTrue);
      // Both the 3x3 and the cross (full row 2 and full col 3) are cleared
      expect(boardController.getBlockId(const Position(2, 2)), isNull);
      expect(boardController.getBlockId(const Position(2, 3)), isNull);
      // Column 3 should be cleared
      for (int r = 0; r < 6; r++) {
        expect(boardController.getBlockId(Position(r, 3)), isNull);
      }
    });

    test('4. Targeted Booster (Hammer / Row / Area) executes cleanly across partial grids', () async {
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          addBlock(Position(r, c), BlockColor.purple);
        }
      }

      boosterController.selectBooster(BoosterType.areaBlast);
      final result = await boosterController.executeTargetedBooster(const Position(1, 1));

      expect(result.success, isTrue);
      expect(result.affectedBlockIds.isNotEmpty, isTrue);
      expect(boardController.getBlockId(const Position(1, 1)), isNull);
    });
  });
}
