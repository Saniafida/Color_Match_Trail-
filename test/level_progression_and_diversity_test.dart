import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/game/progression/progression_manager.dart';
import 'package:color_match_trail/game/levels/adventure_level_generator.dart';
import 'package:color_match_trail/game/levels/level_repository.dart';
import 'package:color_match_trail/game/levels/initial_board_generator.dart';
import 'package:color_match_trail/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ServiceLocator.instance.initialize();
  });

  group('Level Progression & Diversity Tests', () {
    late ProgressionManager progressionManager;

    setUp(() {
      progressionManager = ServiceLocator.instance.progressionManager;
      progressionManager.resetProgression();
    });

    test('1. Completing level 5 unlocks level 6 and advances currentLevel', () async {
      // Complete levels 1 through 4
      for (int i = 1; i <= 4; i++) {
        await progressionManager.saveLevelResult(
          levelId: 'level_$i',
          score: 2000 * i,
          stars: 2,
          movesUsed: 12,
          highestCombo: 2,
          completed: true,
        );
      }

      expect(progressionManager.canPlayLevel('level_5'), isTrue);
      expect(progressionManager.canPlayLevel('level_6'), isFalse);

      // Complete level 5 (World 1 boundary)
      await progressionManager.saveLevelResult(
        levelId: 'level_5',
        score: 12000,
        stars: 3,
        movesUsed: 15,
        highestCombo: 3,
        completed: true,
      );

      // Level 6 MUST be unlocked now!
      expect(progressionManager.canPlayLevel('level_6'), isTrue);
      expect(progressionManager.currentPlayableLevel, equals('level_6'));
    });

    test('2. Level 6 loads cleanly with valid board, colors, and goals', () async {
      final repo = LevelRepository();
      final level6 = await repo.getLevel(6);

      expect(level6.id, equals(6));
      expect(level6.boardConfig.rows, equals(7));
      expect(level6.boardConfig.columns, equals(7));
      expect(level6.goals.isNotEmpty, isTrue);
      expect(level6.colorConfig?.availableColors.isNotEmpty, isTrue);

      // Verify board generates without crashing
      final generator = InitialBoardGenerator();
      final board = generator.generate(level6);
      expect(board.blocks.length, equals(49)); // 7x7 = 49
    });

    test('3. Generator generates all 147 levels with rich variety and distinct configurations', () {
      final Set<String> goalSignatures = {};
      final Set<int> moveLimits = {};
      final Set<int> rowsSet = {};

      for (int i = 1; i <= 147; i++) {
        final level = AdventureLevelGenerator.generateLevel(i);
        expect(level.id, equals(i));
        expect(level.goals.isNotEmpty, isTrue);

        for (final goal in level.goals) {
          expect(goal.targetAmount, greaterThan(0));
          if (goal.type == GoalType.clearColor) {
            expect(goal.color, isNotNull);
          }
        }

        // Collect signatures to verify variety
        final sig = '${level.boardConfig.rows}x${level.boardConfig.columns}_${level.goals.map((g) => "${g.type.name}:${g.color?.name ?? g.specialType?.name ?? 'all'}:${g.targetAmount}").join(",")}';
        goalSignatures.add(sig);
        moveLimits.add(level.movesLimit ?? 25);
        rowsSet.add(level.boardConfig.rows);
      }

      // Ensure diverse goal patterns across 147 levels
      expect(goalSignatures.length, greaterThan(100)); // Over 100 unique level signatures
      expect(moveLimits.length, greaterThan(8)); // Varied move limits
      expect(rowsSet.contains(6), isTrue); // 6x6 early
      expect(rowsSet.contains(7), isTrue); // 7x7 mid
      expect(rowsSet.contains(8), isTrue); // 8x8 advanced
    });

    test('4. All 15 worlds are generated covering all 147 levels', () {
      final worlds = AdventureLevelGenerator.generateAllWorlds();
      expect(worlds.length, equals(15));
      expect(worlds.first.levelIds.first, equals('level_1'));
      expect(worlds.last.levelIds.last, equals('level_147'));

      final totalLevels = worlds.fold<int>(0, (sum, w) => sum + w.levelIds.length);
      expect(totalLevels, equals(147));
    });
  });
}
