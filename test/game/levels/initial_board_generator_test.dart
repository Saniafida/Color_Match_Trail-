import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/level.dart';
import 'package:color_match_trail/models/block.dart';
import 'package:color_match_trail/game/levels/board_config.dart';
import 'package:color_match_trail/game/levels/level_color_config.dart';
import 'package:color_match_trail/game/levels/initial_board_generator.dart';
import 'package:color_match_trail/game/levels/block_generation_config.dart';

void main() {
  group('InitialBoardGenerator', () {
    late InitialBoardGenerator generator;

    setUp(() {
      generator = InitialBoardGenerator();
    });

    test('generates correct dimensions and colors', () {
      final config = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: 6),
        colorConfig: const LevelColorConfig(
          availableColors: [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.yellow],
        ),
      );

      final board = generator.generate(config);

      expect(board.rows, 6);
      expect(board.columns, 6);
      expect(board.cells.length, 36);

      final idSet = <String>{};
      for (var block in board.blocks.values) {
        expect(config.colorConfig!.availableColors.contains(block.color), isTrue);
        idSet.add(block.id);
      }
      expect(idSet.length, 36); // Unique IDs
    });

    test('generates identical boards for same seed', () {
      final config = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: 6),
        colorConfig: const LevelColorConfig(
          availableColors: [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.yellow],
        ),
      );

      final board1 = generator.generate(config, randomSeed: 12345);
      final board2 = generator.generate(config, randomSeed: 12345);
      
      expect(board1.blocks.length, board2.blocks.length);

      for (var cell1 in board1.cells) {
        final cell2 = board2.cells.firstWhere((c) => c.position == cell1.position);
        final block1 = board1.blocks[cell1.blockId];
        final block2 = board2.blocks[cell2.blockId];
        expect(block1?.color, block2?.color);
      }
    });

    test('generates different boards for different seeds', () {
      final config = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: 6),
        colorConfig: const LevelColorConfig(
          availableColors: [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.yellow],
        ),
      );

      final board1 = generator.generate(config, randomSeed: 12345);
      final board2 = generator.generate(config, randomSeed: 67890);

      bool isDifferent = false;
      for (var cell1 in board1.cells) {
        final cell2 = board2.cells.firstWhere((c) => c.position == cell1.position);
        final block1 = board1.blocks[cell1.blockId];
        final block2 = board2.blocks[cell2.blockId];
        if (block1?.color != block2?.color) {
          isDifferent = true;
          break;
        }
      }
      expect(isDifferent, isTrue);
    });

    test('prevents initial matches when allowInitialMatches is false', () {
      final config = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: 6),
        colorConfig: const LevelColorConfig(
          availableColors: [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.yellow],
        ),
        blockGenerationConfig: const BlockGenerationConfig(
          allowInitialMatches: false,
        ),
      );

      final board = generator.generate(config);

      // We simply check that no 3 adjacent blocks share a color horizontally or vertically
      for (int r = 0; r < 6; r++) {
        for (int c = 0; c < 4; c++) {
          final id1 = board.cells.firstWhere((cell) => cell.position.row == r && cell.position.column == c).blockId;
          final id2 = board.cells.firstWhere((cell) => cell.position.row == r && cell.position.column == c + 1).blockId;
          final id3 = board.cells.firstWhere((cell) => cell.position.row == r && cell.position.column == c + 2).blockId;
          
          final c1 = board.blocks[id1]?.color;
          final c2 = board.blocks[id2]?.color;
          final c3 = board.blocks[id3]?.color;
          
          expect(c1 == c2 && c2 == c3, isFalse, reason: 'Horizontal match found at row $r');
        }
      }
      
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 6; c++) {
          final id1 = board.cells.firstWhere((cell) => cell.position.row == r && cell.position.column == c).blockId;
          final id2 = board.cells.firstWhere((cell) => cell.position.row == r + 1 && cell.position.column == c).blockId;
          final id3 = board.cells.firstWhere((cell) => cell.position.row == r + 2 && cell.position.column == c).blockId;
          
          final c1 = board.blocks[id1]?.color;
          final c2 = board.blocks[id2]?.color;
          final c3 = board.blocks[id3]?.color;
          
          expect(c1 == c2 && c2 == c3, isFalse, reason: 'Vertical match found at col $c');
        }
      }
    });
  });
}
