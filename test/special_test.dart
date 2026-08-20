import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/specials/special.dart';
import 'package:color_match_trail/game/blast/blast.dart';
import 'package:color_match_trail/game/trail/match_result.dart';

void main() {
  group('Special Blocks & BlastController', () {
    late BoardController boardController;
    late SpecialController specialController;
    late BlastController blastController;
    
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
      
      
      blockRegistry.clear();
      
      // Fill the board with mock blocks
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          final pos = Position(r, c);
          final id = 'block_${r}_$c';
          blockRegistry[id] = Block(id: id, color: BlockColor.red, position: pos);
          boardController.setBlockId(pos, id);
        }
      }
    });

    test('TEST 1: 5-block match creates Line Special', () async {
      final match = MatchResult(
        isValid: true,
        length: 5,
        blockIds: ['block_0_0', 'block_0_1', 'block_0_2', 'block_0_3', 'block_0_4'],
        positions: [Position(0,0), Position(0,1), Position(0,2), Position(0,3), Position(0,4)],
        connectionType: ConnectionType.normal,
        specialCreationHint: SpecialCreationType.lineBlast,
        color: BlockColor.red,
      );
      
      final result = await blastController.processMatch(match);
      
      // The middle block is block_0_2. It should survive and become a line blast.
      expect(result.destroyedBlockIds.contains('block_0_2'), isFalse);
      expect(result.destroyedBlockIds.length, 4); // The other 4 are destroyed
      
      final specialBlock = blockRegistry['block_0_2']!;
      expect(specialBlock.specialType, SpecialBlockType.horizontalLine);
    });

    test('TEST 6: Horizontal Line clears row', () {
      final result = specialController.activateSpecial(
        const SpecialActivationRequest(
          blockId: 'block_0_0',
          position: Position(0, 0),
          type: SpecialBlockType.horizontalLine,
          color: BlockColor.red,
        )
      );
      
      expect(result.targetPositions.length, 8); // 8 columns in row 0
      for (int c = 0; c < 8; c++) {
        expect(result.targetPositions.contains(Position(0, c)), isTrue);
      }
    });

    test('TEST 7: Vertical Line clears column', () {
      final result = specialController.activateSpecial(
        const SpecialActivationRequest(
          blockId: 'block_0_0',
          position: Position(0, 0),
          type: SpecialBlockType.verticalLine,
          color: BlockColor.red,
        )
      );
      
      expect(result.targetPositions.length, 8); // 8 rows in col 0
      for (int r = 0; r < 8; r++) {
        expect(result.targetPositions.contains(Position(r, 0)), isTrue);
      }
    });

    test('TEST 8: Bomb clears 3x3', () {
      final result = specialController.activateSpecial(
        const SpecialActivationRequest(
          blockId: 'block_3_3',
          position: Position(3, 3),
          type: SpecialBlockType.bomb,
          color: BlockColor.red,
        )
      );
      
      expect(result.targetPositions.length, 9); // 3x3
    });

    test('TEST 9: Color Special clears matching color', () {
      // Set some blocks to blue
      blockRegistry['block_0_0'] = blockRegistry['block_0_0']!.copyWith(color: BlockColor.blue);
      blockRegistry['block_1_1'] = blockRegistry['block_1_1']!.copyWith(color: BlockColor.blue);
      blockRegistry['block_2_2'] = blockRegistry['block_2_2']!.copyWith(color: BlockColor.blue);
      
      final result = specialController.activateSpecial(
        const SpecialActivationRequest(
          blockId: 'block_7_7',
          position: Position(7, 7),
          type: SpecialBlockType.colorSpecial,
          color: BlockColor.blue, // Targeting blue
        )
      );
      
      // Should target the 3 blue blocks + itself
      expect(result.targetPositions.length, 4);
    });

    test('TEST 13: Special chain reaction does not recurse infinitely', () {
      // Setup two line specials pointing at each other
      blockRegistry['block_0_0'] = blockRegistry['block_0_0']!.copyWith(specialType: SpecialBlockType.horizontalLine);
      blockRegistry['block_0_7'] = blockRegistry['block_0_7']!.copyWith(specialType: SpecialBlockType.horizontalLine);
      
      final result = specialController.activateSpecial(
        const SpecialActivationRequest(
          blockId: 'block_0_0',
          position: Position(0, 0),
          type: SpecialBlockType.horizontalLine,
          color: BlockColor.red,
        )
      );
      
      // It should process both but not loop infinitely
      expect(result.targetPositions.length, 8); // Both clear row 0, duplicates removed
    });
  });
}
