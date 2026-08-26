import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/levels/adventure_level_generator.dart';
import 'package:color_match_trail/game/levels/level_repository.dart';
import 'package:color_match_trail/game/levels/initial_board_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdventureLevelGenerator Tests', () {
    test('Generates valid LevelDefinitions for all 147 levels', () {
      for (int i = 1; i <= 147; i++) {
        final level = AdventureLevelGenerator.generateLevel(i);
        expect(level.id, equals(i));
        expect(level.boardConfig.rows, inInclusiveRange(6, 8));
        expect(level.boardConfig.columns, inInclusiveRange(6, 8));
        expect(level.movesLimit, isNotNull);
        expect(level.movesLimit!, inInclusiveRange(20, 45));
        expect(level.goals.isNotEmpty, isTrue);
        expect(level.colorConfig?.availableColors.isNotEmpty, isTrue);
        expect(level.specialConfig?.enabled, isTrue);
        expect(level.boosterConfig?.allowedBoosters.isNotEmpty, isTrue);
      }
    });

    test('InitialBoardGenerator succeeds on generated levels', () {
      final boardGen = InitialBoardGenerator();
      for (final lvlNum in [1, 5, 10, 25, 50, 100, 147]) {
        final level = AdventureLevelGenerator.generateLevel(lvlNum);
        final board = boardGen.generate(level);
        expect(board.rows, equals(level.boardConfig.rows));
        expect(board.columns, equals(level.boardConfig.columns));
        expect(board.blocks.length, equals(board.rows * board.columns));
      }
    });

    test('Generates valid LevelDefinitionData for all 147 levels', () {
      for (int i = 1; i <= 147; i++) {
        final data = AdventureLevelGenerator.generateData(i);
        expect(data.levelId, equals('level_$i'));
        expect(data.goals.isNotEmpty, isTrue);
        expect(data.moveLimit, greaterThanOrEqualTo(20));
        expect(data.starThresholds.length, equals(3));
        expect(data.starThresholds[0] < data.starThresholds[1], isTrue);
        expect(data.starThresholds[1] < data.starThresholds[2], isTrue);
      }
    });

    test('Generates all 15 campaign worlds encompassing all 147 levels', () {
      final worlds = AdventureLevelGenerator.generateAllWorlds();
      expect(worlds.length, equals(15));
      expect(worlds.first.levelIds.first, equals('level_1'));
      expect(worlds.last.levelIds.last, equals('level_147'));

      final allLevelIds = worlds.expand((w) => w.levelIds).toList();
      expect(allLevelIds.length, equals(147));
      for (int i = 1; i <= 147; i++) {
        expect(allLevelIds.contains('level_$i'), isTrue);
      }
    });

    test('LevelRepository loads procedural levels beyond static JSON', () async {
      final repo = LevelRepository();
      final level50 = await repo.getLevel(50);
      expect(level50.id, equals(50));
      expect(level50.boardConfig.rows, equals(8));
      expect(level50.goals.isNotEmpty, isTrue);

      final level147 = await repo.getLevel(147);
      expect(level147.id, equals(147));
    });
  });
}
