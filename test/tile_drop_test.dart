import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/tile_drop/tile_drop_level_generator.dart';

void main() {
  group('TileDropLevelGenerator Tests', () {
    test('Level 1 is very easy with 2 colors and Red goal', () {
      final level = TileDropLevelGenerator.getLevel(1);
      expect(level.levelNumber, 1);
      expect(level.activeColors.length, 2);
      expect(level.activeColors, contains(BlockColor.red));
      expect(level.activeColors, contains(BlockColor.yellow));
      expect(level.targetRequirements[BlockColor.red], 6);
      expect(level.moves, 15);
      expect(level.columns, 5);
      expect(level.rows, 7);
      expect(level.initialGrid, isNotNull);
    });

    test('Level 5 introduces 3 colors with balanced moves', () {
      final level = TileDropLevelGenerator.getLevel(5);
      expect(level.levelNumber, 5);
      expect(level.activeColors.length, 3);
      expect(level.targetRequirements[BlockColor.red], 12);
      expect(level.targetRequirements[BlockColor.yellow], 10);
      expect(level.targetRequirements[BlockColor.blue], 10);
      expect(level.moves, 24);
      expect(level.columns, 7);
      expect(level.rows, 8);
    });

    test('Level 10 has 5 colors and boss level requirements', () {
      final level = TileDropLevelGenerator.getLevel(10);
      expect(level.levelNumber, 10);
      expect(level.activeColors.length, 5);
      expect(level.moves, 30);
      expect(level.targetRequirements.length, 4);
    });

    test('Procedural levels 15, 30, 50 generate valid progressive levels', () {
      for (final lvl in [15, 30, 50]) {
        final level = TileDropLevelGenerator.getLevel(lvl);
        expect(level.levelNumber, lvl);
        expect(level.moves, greaterThanOrEqualTo(20));
        expect(level.goalTotal, greaterThan(0));
        expect(level.activeColors.length, greaterThanOrEqualTo(4));
        expect(level.columns, 7);
        expect(level.rows, 8);
      }
    });
  });
}
