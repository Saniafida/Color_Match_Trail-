import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/levels/level_playability_validator.dart';
import 'package:color_match_trail/models/data/level_definition.dart';
import 'package:color_match_trail/models/goal.dart';

void main() {
  group('Module 55 Level Playability Validator Tests', () {
    const validator = LevelPlayabilityValidator();

    test('1. Normal configured level is playable with valid starting moves', () {
      const normalLevel = LevelDefinitionData(
        levelId: 'level_1',
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 15)],
        moveLimit: 25,
      );

      final result = validator.validatePlayability(normalLevel, seed: 1337);
      expect(result.isPlayable, isTrue);
      expect(result.validStartingMovesCount, greaterThan(0));
    });

    test('2. Level with 0 moves is flagged as unplayable', () {
      const zeroMoveLevel = LevelDefinitionData(
        levelId: 'level_zero_move',
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 15)],
        moveLimit: 0,
      );

      final result = validator.validatePlayability(zeroMoveLevel);
      expect(result.isPlayable, isFalse);
      expect(result.reason, contains('0 moves'));
    });

    test('3. Level with empty goals is flagged as unplayable', () {
      const noGoalLevel = LevelDefinitionData(
        levelId: 'level_no_goal',
        boardRows: 6,
        boardColumns: 6,
        goals: [],
        moveLimit: 20,
      );

      final result = validator.validatePlayability(noGoalLevel);
      expect(result.isPlayable, isFalse);
      expect(result.reason, contains('no objectives'));
    });
  });
}
