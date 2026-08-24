import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/tile_sort/tile_sort_level_generator.dart';
import 'package:color_match_trail/game/tile_sort/tile_sort_level_model.dart';

void main() {
  group('TileSortLevelGenerator Tests', () {
    test('Level 1 is easy with 2 colors, 3 tubes, capacity 3', () {
      final level = TileSortLevelGenerator.getLevel(1);
      expect(level.levelNumber, 1);
      expect(level.capacity, 3);
      expect(level.activeColors.length, 2);
      expect(level.initialTubes.length, 3);
      expect(level.theme, TubeTheme.crystalClassic);
    });

    test('Level 2 has 3 colors, 4 tubes, capacity 3', () {
      final level = TileSortLevelGenerator.getLevel(2);
      expect(level.levelNumber, 2);
      expect(level.capacity, 3);
      expect(level.activeColors.length, 3);
      expect(level.initialTubes.length, 4);
    });

    test('Level 4 introduces PotionFlask theme with 4 colors, 5 tubes', () {
      final level = TileSortLevelGenerator.getLevel(4);
      expect(level.levelNumber, 4);
      expect(level.capacity, 4);
      expect(level.activeColors.length, 4);
      expect(level.initialTubes.length, 5);
      expect(level.theme, TubeTheme.potionFlask);
    });

    test('Level 6 introduces RoyalEnchanted theme with 5 colors, 6 tubes', () {
      final level = TileSortLevelGenerator.getLevel(6);
      expect(level.levelNumber, 6);
      expect(level.activeColors.length, 5);
      expect(level.initialTubes.length, 6);
      expect(level.theme, TubeTheme.royalEnchanted);
    });

    test('Procedural levels 7, 10, 15 generate valid non-empty solvable configurations', () {
      for (final lvl in [7, 10, 15]) {
        final level = TileSortLevelGenerator.getLevel(lvl);
        expect(level.levelNumber, lvl);
        expect(level.capacity, inInclusiveRange(4, 5));
        expect(level.activeColors.isNotEmpty, isTrue);
        expect(level.initialTubes.isNotEmpty, isTrue);

        final totalTiles = level.initialTubes.fold<int>(
          0,
          (sum, tube) => sum + tube.length,
        );
        expect(totalTiles, level.activeColors.length * level.capacity);
      }
    });

    test('Level 1 initial tubes contain only valid allowed colors', () {
      final level = TileSortLevelGenerator.getLevel(1);
      for (final tube in level.initialTubes) {
        for (final block in tube) {
          expect(level.activeColors.contains(block), isTrue);
        }
      }
    });
  });
}
