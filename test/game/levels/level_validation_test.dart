import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/levels/level_validator.dart';
import 'package:color_match_trail/models/data/level_definition.dart';
import 'package:color_match_trail/models/goal.dart';

void main() {
  group('Module 55 Level Validator Tests', () {
    const validator = LevelValidator();

    test('1. Valid level passes validation', () {
      const validLevel = LevelDefinitionData(
        levelId: 'level_1',
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 15)],
        moveLimit: 25,
        scoreTarget: 1000,
      );

      final report = validator.validateData(validLevel);
      expect(report.isValid, isTrue);
      expect(report.errors, isEmpty);
    });

    test('2. Zero move count is rejected', () {
      const zeroMoveLevel = LevelDefinitionData(
        levelId: 'level_bad',
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 15)],
        moveLimit: 0,
      );

      final report = validator.validateData(zeroMoveLevel);
      expect(report.isValid, isFalse);
      expect(report.errors, anyElement(contains('Move limit must be greater than 0')));
    });

    test('3. Invalid board rows/columns rejected', () {
      const badBoardLevel = LevelDefinitionData(
        levelId: 'level_bad_board',
        boardRows: 0,
        boardColumns: 15,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 15)],
        moveLimit: 20,
      );

      final report = validator.validateData(badBoardLevel);
      expect(report.isValid, isFalse);
      expect(report.errors.length, greaterThanOrEqualTo(2));
    });

    test('4. Campaign validation detects duplicate level IDs', () {
      const levelA = LevelDefinitionData(
        levelId: 'level_1',
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 15)],
        moveLimit: 20,
      );

      const levelADuplicate = LevelDefinitionData(
        levelId: 'level_1', // duplicate ID!
        boardRows: 6,
        boardColumns: 6,
        goals: [GoalDefinition(id: 'g2', type: GoalType.clearColor, targetAmount: 20)],
        moveLimit: 25,
      );

      final reports = validator.validateCampaign([levelA, levelADuplicate]);
      expect(reports[0].isValid, isTrue);
      expect(reports[1].isValid, isFalse);
      expect(reports[1].errors, anyElement(contains('Duplicate Level ID')));
    });
  });
}
