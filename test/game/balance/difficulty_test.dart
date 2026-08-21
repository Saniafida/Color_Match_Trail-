import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/balance/difficulty_manager.dart';
import 'package:color_match_trail/game/balance/difficulty_tier.dart';
import 'package:color_match_trail/game/balance/difficulty_test_runner.dart';
import 'package:color_match_trail/models/data/level_definition.dart';
import 'package:color_match_trail/models/goal.dart';

void main() {
  group('Module 55 Difficulty Manager & Test Runner Tests', () {
    const difficultyManager = DifficultyManager();
    const testRunner = DifficultyTestRunner();

    test('1. Difficulty evaluation scales properly with board and goals', () {
      const easyLevel = LevelDefinitionData(
        levelId: 'level_1',
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 10)],
        moveLimit: 25,
        difficulty: 'easy',
      );

      const hardLevel = LevelDefinitionData(
        levelId: 'level_10',
        boardRows: 8,
        boardColumns: 8,
        goals: [
          GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 40),
          GoalDefinition(id: 'g2', type: GoalType.clearBlocks, targetAmount: 50),
        ],
        moveLimit: 25,
        difficulty: 'hard',
      );

      final easyBalance = difficultyManager.evaluateLevel(easyLevel);
      final hardBalance = difficultyManager.evaluateLevel(hardLevel);

      expect(easyBalance.tier, equals(DifficultyTier.easy));
      expect(hardBalance.tier, equals(DifficultyTier.hard));
      expect(hardBalance.complexityScore, greaterThan(easyBalance.complexityScore));
      expect(easyBalance.estimatedClearRate, greaterThan(hardBalance.estimatedClearRate));
    });

    test('2. Detects sudden difficulty spikes between adjacent levels', () {
      const level1 = LevelDefinitionData(
        levelId: 'level_1',
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 10)],
        moveLimit: 25,
        difficulty: 'easy',
      );

      const level2Spike = LevelDefinitionData(
        levelId: 'level_2',
        boardRows: 8,
        boardColumns: 8,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 50)],
        moveLimit: 15,
        difficulty: 'expert', // Jump from Easy to Expert!
      );

      final warnings = difficultyManager.detectDifficultySpikes([level1, level2Spike]);
      expect(warnings, isNotEmpty);
      expect(warnings.first, contains('Difficulty spike detected'));
    });

    test('3. DifficultyTestRunner simulates level completion offline', () {
      const level = LevelDefinitionData(
        levelId: 'level_1',
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 15)],
        moveLimit: 25,
        difficulty: 'easy',
      );

      final simResult = testRunner.evaluate(level, simulationRuns: 3);
      expect(simResult.isPlayable, isTrue);
      expect(simResult.estimatedMoves, greaterThan(0));
      expect(simResult.deadBoardFrequency, lessThanOrEqualTo(0.5));
    });
  });
}
