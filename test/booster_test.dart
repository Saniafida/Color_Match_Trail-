import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/specials/special.dart';
import 'package:color_match_trail/game/blast/blast.dart';
import 'package:color_match_trail/game/boosters/booster.dart';

void main() {
  group('Booster System', () {
    late BoardController boardController;
    late SpecialController specialController;
    late BlastController blastController;
    late BoosterController boosterController;
    
    final Map<String, Block> blockRegistry = {};
    
    setUp(() {
      boardController = BoardController(rows: 8, columns: 8);
      
      specialController = SpecialController(
        boardController: boardController,
        getBlock: (id) => blockRegistry[id],
      );
      
      blastController = BlastController(
        boardController: boardController,
        getBlock: (id) => blockRegistry[id],
        onUpdateBlock: (block) => blockRegistry[block.id] = block,
        onRemoveBlock: (id) => blockRegistry.remove(id),
        specialController: specialController,
      );
      
      boosterController = BoosterController(
        boardController: boardController,
        blastController: blastController,
        getBlock: (id) => blockRegistry[id],
        onMoveBlock: (id, pos) {
          blockRegistry[id] = blockRegistry[id]!.copyWith(position: pos);
        },
        specialController: specialController,
      );
      
      
      blockRegistry.clear();
      
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          final pos = Position(r, c);
          final id = 'block_${r}_$c';
          blockRegistry[id] = Block(id: id, color: BlockColor.red, position: pos);
          boardController.setBlockId(pos, id);
        }
      }
    });

    test('TEST 14: Hammer removes one target', () async {
      boosterController.selectBooster(BoosterType.hammer);
      expect(boosterController.state, BoosterUseState.selecting);
      
      final result = await boosterController.executeTargetedBooster(const Position(0, 0));
      
      expect(result.success, isTrue);
      expect(result.affectedBlockIds.length, 1);
      expect(result.affectedBlockIds.first, 'block_0_0');
      expect(blockRegistry.containsKey('block_0_0'), isFalse);
      expect(boosterController.inventory.getQuantity(BoosterType.hammer), 2); // 3 - 1
    });

    test('TEST 15: Hammer on special activates special', () async {
      blockRegistry['block_3_3'] = blockRegistry['block_3_3']!.copyWith(specialType: SpecialBlockType.bomb);
      
      boosterController.selectBooster(BoosterType.hammer);
      final result = await boosterController.executeTargetedBooster(const Position(3, 3));
      
      expect(result.success, isTrue);
      expect(result.affectedPositions.length, 9); // Bomb clears 3x3
    });

    test('TEST 18: Row Clear clears correct row', () async {
      boosterController.selectBooster(BoosterType.rowClear);
      final result = await boosterController.executeTargetedBooster(const Position(2, 4)); // Targets row 2
      
      expect(result.success, isTrue);
      expect(result.affectedPositions.length, 8); // 8 cols
      for (int c = 0; c < 8; c++) {
        expect(boardController.getBlockId(Position(2, c)), isNull);
      }
    });

    test('TEST 20: Zero inventory prevents use', () {
      boosterController.loadInventory(const BoosterInventory(quantities: {BoosterType.hammer: 0}));
      
      boosterController.selectBooster(BoosterType.hammer);
      expect(boosterController.state, BoosterUseState.idle); // Denied
    });

    test('TEST 21: Cancelled booster does not consume inventory', () {
      expect(boosterController.inventory.getQuantity(BoosterType.hammer), 3);
      
      boosterController.selectBooster(BoosterType.hammer);
      boosterController.cancelSelection();
      
      expect(boosterController.inventory.getQuantity(BoosterType.hammer), 3);
      expect(boosterController.state, BoosterUseState.cancelled); // Will eventually reset to idle
    });
  });
}
