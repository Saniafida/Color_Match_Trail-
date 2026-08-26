import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/models/power_up_block.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/blast/blast.dart';
import 'package:color_match_trail/game/specials/special.dart';
import 'package:color_match_trail/game/specials/power_up_config.dart';
import 'package:color_match_trail/game/specials/power_up_manager.dart';

void main() {
  group('Power-Up Transformation System Tests', () {
    late BoardController boardController;
    late Map<String, Block> blocks;
    late SpecialController specialController;
    late BlastController blastController;
    late PowerUpManager powerUpManager;

    void addBlock(Position pos, BlockColor color, {String? id}) {
      final blockId = id ?? 'b_${pos.row}_${pos.column}';
      final block = Block(
        id: blockId,
        color: color,
        position: pos,
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
    });

    test('1. Configurable power-up mapping table validation', () {
      expect(PowerUpConfig.getPowerUpTypeForLength(3), PowerUpType.none);
      expect(PowerUpConfig.getPowerUpTypeForLength(4), PowerUpType.smallArea);
      expect(PowerUpConfig.getPowerUpTypeForLength(5), PowerUpType.bomb); // Mandatory Bomb
      expect(PowerUpConfig.getPowerUpTypeForLength(6), PowerUpType.crossBlast);
      expect(PowerUpConfig.getPowerUpTypeForLength(7), PowerUpType.colorBomb);
      expect(PowerUpConfig.getPowerUpTypeForLength(8), PowerUpType.megaBomb);
      expect(PowerUpConfig.getPowerUpTypeForLength(9), PowerUpType.magicWand);
      expect(PowerUpConfig.getPowerUpTypeForLength(12), PowerUpType.magicWand);
    });

    test('2. Creation cell selection follows strict priority order', () {
      final positions = [
        const Position(0, 0),
        const Position(0, 1),
        const Position(0, 2),
        const Position(0, 3),
        const Position(0, 4),
      ];

      // Priority 1: Last selected block in trail
      final chosen1 = powerUpManager.selectCreationCell(
        connectedPositions: positions,
      );
      expect(chosen1, equals(const Position(0, 4)));

      // Priority 2: Release position mapped to group if last is invalid
      final invalidLastList = [
        const Position(0, 0),
        const Position(0, 1),
        const Position(99, 99), // out of bounds
      ];
      final chosen2 = powerUpManager.selectCreationCell(
        connectedPositions: invalidLastList,
        releasePosition: const Position(0, 1),
      );
      expect(chosen2, equals(const Position(0, 1)));
    });

    test('3. 5-block trail creates Bomb on chosen cell, removes 4 other blocks, inherits color', () async {
      final positions = [
        const Position(1, 0),
        const Position(1, 1),
        const Position(1, 2),
        const Position(1, 3),
        const Position(1, 4),
      ];
      final blockIds = <String>[];

      for (int i = 0; i < positions.length; i++) {
        final id = 'red_$i';
        addBlock(positions[i], BlockColor.red, id: id);
        blockIds.add(id);
      }

      final result = await powerUpManager.processTrailPowerUp(
        blockIds: blockIds,
        positions: positions,
        color: BlockColor.red,
      );

      expect(result.transformed, isTrue);
      expect(result.powerUpType, PowerUpType.bomb);
      expect(result.specialType, SpecialBlockType.bomb);
      expect(result.sourceColor, BlockColor.red);
      expect(result.removedBlockIds.length, 4);

      // Verify transformed block is still on the board at (1, 4)
      final transformedBlockId = boardController.getBlockId(const Position(1, 4));
      expect(transformedBlockId, equals('red_4'));

      final transformedBlock = blocks[transformedBlockId];
      expect(transformedBlock, isNotNull);
      expect(transformedBlock!.specialType, equals(SpecialBlockType.bomb));
      expect(transformedBlock.color, equals(BlockColor.red));
      expect(transformedBlock.isPowerUp, isTrue);

      // Verify other 4 cells are cleared
      expect(boardController.getBlockId(const Position(1, 0)), isNull);
      expect(boardController.getBlockId(const Position(1, 1)), isNull);
      expect(boardController.getBlockId(const Position(1, 2)), isNull);
      expect(boardController.getBlockId(const Position(1, 3)), isNull);
    });

    test('4. 4-block trail creates Small Area power-up', () async {
      final positions = [
        const Position(2, 0),
        const Position(2, 1),
        const Position(2, 2),
        const Position(2, 3),
      ];
      final blockIds = <String>[];

      for (int i = 0; i < positions.length; i++) {
        final id = 'blue_$i';
        addBlock(positions[i], BlockColor.blue, id: id);
        blockIds.add(id);
      }

      final result = await powerUpManager.processTrailPowerUp(
        blockIds: blockIds,
        positions: positions,
        color: BlockColor.blue,
      );

      expect(result.transformed, isTrue);
      expect(result.powerUpType, PowerUpType.smallArea);
      expect(result.sourceColor, BlockColor.blue);
      expect(result.removedBlockIds.length, 3);
    });

    test('5. 6-block trail creates Cross Blast power-up', () async {
      final positions = [
        const Position(0, 0),
        const Position(0, 1),
        const Position(0, 2),
        const Position(0, 3),
        const Position(0, 4),
        const Position(0, 5),
      ];
      final blockIds = <String>[];

      for (int i = 0; i < positions.length; i++) {
        final id = 'green_$i';
        addBlock(positions[i], BlockColor.green, id: id);
        blockIds.add(id);
      }

      final result = await powerUpManager.processTrailPowerUp(
        blockIds: blockIds,
        positions: positions,
        color: BlockColor.green,
      );

      expect(result.transformed, isTrue);
      expect(result.powerUpType, PowerUpType.crossBlast);
      expect(result.specialType, SpecialBlockType.crossBlast);
      expect(result.removedBlockIds.length, 5);
    });

    test('6. Tap power-up triggers activation and blast effect', () async {
      // Setup a 3x3 surrounding board with a Bomb in the center at (2, 2)
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          addBlock(Position(r, c), BlockColor.yellow);
        }
      }

      // Convert (2, 2) into a bomb
      final bombPos = const Position(2, 2);
      final bombId = boardController.getBlockId(bombPos)!;
      blocks[bombId] = blocks[bombId]!.copyWith(
        specialType: SpecialBlockType.bomb,
        type: BlockType.bomb,
      );

      // Tap to activate
      final blastResult = await powerUpManager.activatePowerUpAt(bombPos);

      expect(blastResult.success, isTrue);
      expect(blastResult.destroyedCount, greaterThanOrEqualTo(9)); // 3x3 bomb destroyed all 9 cells
      expect(boardController.getBlockId(bombPos), isNull);
    });
  });
}
