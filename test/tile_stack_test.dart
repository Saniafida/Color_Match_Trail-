import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/basket_collect/basket_collect_level_generator.dart';
import 'package:color_match_trail/models/models.dart';

void main() {
  group('BasketCollectLevelGenerator Tests', () {
    test('Level 1 is very easy with slow fall speed and 5 goal', () {
      final level = BasketCollectLevelGenerator.getLevel(1);
      expect(level.levelNumber, 1);
      expect(level.goalTotal, 5);
      expect(level.fallSpeedMultiplier, lessThan(1.0));
      expect(level.activeColors.length, 2);
    });

    test('Level 5 is balanced with goal 20 and 25 moves', () {
      final level = BasketCollectLevelGenerator.getLevel(5);
      expect(level.levelNumber, 5);
      expect(level.goalTotal, 20);
      expect(level.moves, 25);
      expect(level.activeColors.contains(BlockColor.red), isTrue);
      expect(level.activeColors.contains(BlockColor.green), isTrue);
      expect(level.activeColors.contains(BlockColor.blue), isTrue);
      expect(level.activeColors.contains(BlockColor.yellow), isTrue);
    });

    test('Procedural levels 10, 20 generate valid progressive goals and speeds', () {
      for (final lvl in [10, 20]) {
        final level = BasketCollectLevelGenerator.getLevel(lvl);
        expect(level.levelNumber, lvl);
        expect(level.goalTotal, greaterThanOrEqualTo(40));
        expect(level.moves, greaterThan(20));
        expect(level.activeColors.isNotEmpty, isTrue);
      }
    });
  });
}
