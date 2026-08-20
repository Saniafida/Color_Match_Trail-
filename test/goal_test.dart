import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/goals/goal.dart';
import 'package:color_match_trail/game/blast/blast.dart';
import 'package:color_match_trail/game/score/score.dart';
import 'package:color_match_trail/game/specials/special.dart';
import 'package:color_match_trail/game/boosters/booster.dart';

void main() {
  group('GoalController', () {
    late GoalController controller;

    setUp(() {
      controller = GoalController();
    });

    test('TEST 1: Initialize one goal, expected progress = 0', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.clearBlocks, targetAmount: 20),
      ]);

      expect(controller.states.length, 1);
      final state = controller.states.first;
      expect(state.currentAmount, 0);
      expect(state.targetAmount, 20);
      expect(state.completed, false);
      expect(controller.allRequiredGoalsCompleted, false);
    });

    test('TEST 2: ClearColor red, blast 5 red, expected progress +5', () {
      controller.initialize([
        const GoalDefinition(
          id: 'g1', 
          type: GoalType.clearColor, 
          targetAmount: 30, 
          color: BlockColor.red,
        ),
      ]);

      controller.onBlastResult(const BlastResult(
        success: true,
        destroyedBlockIds: ['1', '2', '3', '4', '5'],
        destroyedPositions: [],
        destroyedCount: 5,
        color: BlockColor.red,
        source: DestructionSource.playerMatch,
      ));

      final state = controller.states.first;
      expect(state.currentAmount, 5);
      expect(state.completed, false);
    });

    test('TEST 3: Blast blue on Red goal, expected no progress', () {
      controller.initialize([
        const GoalDefinition(
          id: 'g1', 
          type: GoalType.clearColor, 
          targetAmount: 30, 
          color: BlockColor.red,
        ),
      ]);

      controller.onBlastResult(const BlastResult(
        success: true,
        destroyedBlockIds: ['1', '2', '3'],
        destroyedPositions: [],
        destroyedCount: 3,
        color: BlockColor.blue,
        source: DestructionSource.playerMatch,
      ));

      expect(controller.states.first.currentAmount, 0);
    });

    test('TEST 4: ClearBlocks 20, blast 7, expected 7/20', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.clearBlocks, targetAmount: 20),
      ]);

      controller.onBlastResult(const BlastResult(
        success: true,
        destroyedCount: 7,
      ));

      expect(controller.states.first.currentAmount, 7);
    });

    test('TEST 5: Score goal +500 expected 500/target', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.score, targetAmount: 1000),
      ]);

      controller.onScoreEvent(const ScoreEvent(
        eventId: 'test',
        pointsAdded: 500,
        breakdown: ScoreBreakdown(
          destroyedBlocks: 5,
          baseScore: 500,
          connectionMultiplier: 1.0,
          cascadeMultiplier: 1.0,
          comboMultiplier: 1.0,
          finalScore: 500,
          cascadeLevel: 0,
          comboLevel: 0,
        ),
        centerPosition: Position(0, 0),
        isCascade: false,
      ));

      expect(controller.states.first.currentAmount, 500);
    });

    test('TEST 6: Create Bomb', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.createSpecial, targetAmount: 2, specialType: SpecialBlockType.bomb),
      ]);

      controller.onSpecialCreation(const SpecialCreationResult(
        created: true,
        type: SpecialBlockType.bomb,
      ));

      expect(controller.states.first.currentAmount, 1);
    });

    test('TEST 7: Create Line, Bomb goal -> no progress', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.createSpecial, targetAmount: 2, specialType: SpecialBlockType.bomb),
      ]);

      controller.onSpecialCreation(const SpecialCreationResult(
        created: true,
        type: SpecialBlockType.horizontalLine,
      ));

      expect(controller.states.first.currentAmount, 0);
    });

    test('TEST 8: Activate Special', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.activateSpecial, targetAmount: 3, specialType: SpecialBlockType.colorSpecial),
      ]);

      controller.onSpecialActivation(const SpecialActivationResult(
        specialBlockId: 'b1',
        specialType: SpecialBlockType.colorSpecial,
        sourcePosition: Position(0,0),
        success: true,
      ));

      expect(controller.states.first.currentAmount, 1);
    });

    test('TEST 9 & 10: Booster success vs cancel', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.useBooster, targetAmount: 2, boosterType: BoosterType.hammer),
      ]);

      // Cancelled
      controller.onBoosterUse(const BoosterUseResult(
        success: false,
        boosterType: BoosterType.hammer,
        consumed: false,
      ));
      expect(controller.states.first.currentAmount, 0);

      // Success
      controller.onBoosterUse(const BoosterUseResult(
        success: true,
        boosterType: BoosterType.hammer,
        consumed: true,
      ));
      expect(controller.states.first.currentAmount, 1);
    });

    test('TEST 48: Goal Completion clamp and event', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.clearBlocks, targetAmount: 10),
      ]);

      final events = <GoalCompletedEvent>[];
      controller.onCompleted.listen(events.add);

      // Add 8
      controller.onBlastResult(const BlastResult(success: true, destroyedCount: 8));
      expect(controller.states.first.currentAmount, 8);
      expect(controller.states.first.completed, false);
      expect(events.isEmpty, true);

      // Add 5
      controller.onBlastResult(const BlastResult(success: true, destroyedCount: 5));
      expect(controller.states.first.currentAmount, 10); // Clamped
      expect(controller.states.first.completed, true);
      expect(events.length, 1);
      
      // Add 2
      controller.onBlastResult(const BlastResult(success: true, destroyedCount: 2));
      expect(controller.states.first.currentAmount, 10);
      expect(events.length, 1); // No second event
    });

    test('TEST 49: Multiple Goals update independently', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.clearColor, targetAmount: 20, color: BlockColor.red),
        const GoalDefinition(id: 'g2', type: GoalType.score, targetAmount: 5000),
        const GoalDefinition(id: 'g3', type: GoalType.createSpecial, targetAmount: 2, specialType: SpecialBlockType.bomb),
      ]);

      // One action
      controller.onBlastResult(const BlastResult(success: true, destroyedCount: 5, color: BlockColor.red));
      controller.onScoreEvent(const ScoreEvent(
        eventId: 'test',
        pointsAdded: 250,
        breakdown: ScoreBreakdown(
          destroyedBlocks: 5,
          baseScore: 250,
          connectionMultiplier: 1.0,
          cascadeMultiplier: 1.0,
          comboMultiplier: 1.0,
          finalScore: 250,
          cascadeLevel: 0,
          comboLevel: 0,
        ),
        centerPosition: Position(0, 0),
        isCascade: false,
      ));
      controller.onSpecialCreation(const SpecialCreationResult(created: true, type: SpecialBlockType.bomb));

      final stateA = controller.states.firstWhere((s) => s.goalId == 'g1');
      final stateB = controller.states.firstWhere((s) => s.goalId == 'g2');
      final stateC = controller.states.firstWhere((s) => s.goalId == 'g3');

      expect(stateA.currentAmount, 5);
      expect(stateB.currentAmount, 250);
      expect(stateC.currentAmount, 1);
    });

    test('TEST 50: Required vs Optional completion', () {
      controller.initialize([
        const GoalDefinition(id: 'required1', type: GoalType.clearBlocks, targetAmount: 20, isOptional: false),
        const GoalDefinition(id: 'optional1', type: GoalType.createSpecial, targetAmount: 3, specialType: SpecialBlockType.bomb, isOptional: true),
      ]);

      controller.onBlastResult(const BlastResult(success: true, destroyedCount: 20));

      expect(controller.allRequiredGoalsCompleted, true);
      expect(controller.allGoalsCompleted, false);
    });

    test('TEST 51 & 52: Reset and Reload', () {
      controller.initialize([
        const GoalDefinition(id: 'g1', type: GoalType.clearBlocks, targetAmount: 20),
      ]);

      controller.onBlastResult(const BlastResult(success: true, destroyedCount: 15));
      expect(controller.states.first.currentAmount, 15);

      controller.resetGoals();
      expect(controller.states.first.currentAmount, 0);

      // Load new level
      controller.initialize([
        const GoalDefinition(id: 'g2', type: GoalType.clearColor, targetAmount: 30, color: BlockColor.blue),
      ]);

      expect(controller.states.length, 1);
      expect(controller.states.first.goalId, 'g2');
      expect(controller.states.first.currentAmount, 0);
    });
  });
}
