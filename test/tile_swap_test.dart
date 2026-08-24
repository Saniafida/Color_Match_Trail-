import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/tile_swap/tile_swap_level_generator.dart';

void main() {
  group('TileSwapLevelGenerator Tests', () {
    test('Level 1 has all 5 vibrant colors on a 7x7 board and balanced goals', () {
      final level = TileSwapLevelGenerator.getLevel(1);
      expect(level.levelNumber, 1);
      expect(level.activeColors.length, 5);
      expect(level.activeColors, contains(BlockColor.red));
      expect(level.activeColors, contains(BlockColor.yellow));
      expect(level.activeColors, contains(BlockColor.blue));
      expect(level.activeColors, contains(BlockColor.green));
      expect(level.activeColors, contains(BlockColor.purple));
      expect(level.targetRequirements[BlockColor.red], 10);
      expect(level.targetRequirements[BlockColor.yellow], 10);
      expect(level.moves, 22);
      expect(level.columns, 7);
      expect(level.rows, 7);
      expect(level.initialGrid, isNotNull);
      expect(level.initialGrid!.length, 7);
      expect(level.initialGrid![0].length, 7);
    });

    test('Level 5 has all 5 colors on 7x7 board with balanced moves and multiple goals', () {
      final level = TileSwapLevelGenerator.getLevel(5);
      expect(level.levelNumber, 5);
      expect(level.activeColors.length, 5);
      expect(level.targetRequirements[BlockColor.red], 15);
      expect(level.targetRequirements[BlockColor.yellow], 15);
      expect(level.targetRequirements[BlockColor.blue], 15);
      expect(level.moves, 28);
      expect(level.columns, 7);
      expect(level.rows, 7);
    });

    test('Level 10 has 5 colors and boss level requirements on 7x7 board', () {
      final level = TileSwapLevelGenerator.getLevel(10);
      expect(level.levelNumber, 10);
      expect(level.activeColors.length, 5);
      expect(level.moves, 35);
      expect(level.targetRequirements.length, 4);
      expect(level.columns, 7);
      expect(level.rows, 7);
    });

    test('Procedural levels 15, 30, 50 generate valid progressive 7x7 levels with all 5 colors', () {
      for (final lvl in [15, 30, 50]) {
        final level = TileSwapLevelGenerator.getLevel(lvl);
        expect(level.levelNumber, lvl);
        expect(level.moves, greaterThanOrEqualTo(24));
        expect(level.goalTotal, greaterThan(0));
        expect(level.activeColors.length, 5);
        expect(level.columns, 7);
        expect(level.rows, 7);
        expect(level.initialGrid, isNotNull);
        expect(level.initialGrid!.length, 7);
        expect(level.initialGrid![0].length, 7);
      }
    });
  });
}
