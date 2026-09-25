import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/goals/goal_state.dart';
import 'package:color_match_trail/game/level_result/level_result_system.dart';
import 'package:color_match_trail/game/results/level_result_manager.dart';
import 'package:color_match_trail/game/progression/progression_manager.dart';
import 'package:color_match_trail/game/rewards/reward_manager.dart';
import 'package:color_match_trail/game/levels/board_config.dart';
import 'package:color_match_trail/app/routes/routes.dart';
import 'package:color_match_trail/screens/gameplay/gameplay_screen.dart';

class MockProgressionManager extends Fake implements ProgressionManager {
  @override
  Future<void> saveLevelResult({
    required String levelId,
    required int score,
    required int stars,
    required int movesUsed,
    required int highestCombo,
    required bool completed,
  }) async {}
}

class MockRewardManager extends Fake implements RewardManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Level Failed Goals and Boosters Tests', () {
    test('1. LevelResultManager retains currentLevelData and currentFinalResult for dynamic goals', () async {
      final progressionManager = MockProgressionManager();
      final rewardManager = MockRewardManager();

      final manager = LevelResultManager(
        progressionManager: progressionManager,
        rewardManager: rewardManager,
      );

      const levelDef = LevelDefinition(
        id: 11,
        boardConfig: BoardConfig(rows: 7, columns: 7),
        movesLimit: 25,
        goals: [
          GoalDefinition(
            id: 'goal_purple',
            type: GoalType.clearColor,
            targetAmount: 25,
            color: BlockColor.purple,
          ),
          GoalDefinition(
            id: 'goal_rocket',
            type: GoalType.createSpecial,
            targetAmount: 2,
            specialType: SpecialBlockType.horizontalLine,
          ),
        ],
      );

      const finalResult = FinalLevelResult(
        status: GameStatus.lost,
        reason: LevelResultReason.movesExhausted,
        finalScore: 450,
        remainingMoves: 0,
        remainingTime: 0,
        completedGoals: [],
        incompleteGoals: [
          GoalState(
            goalId: 'goal_purple',
            currentAmount: 17,
            targetAmount: 25,
            completed: false,
            isOptional: false,
          ),
          GoalState(
            goalId: 'goal_rocket',
            currentAmount: 1,
            targetAmount: 2,
            completed: false,
            isOptional: false,
          ),
        ],
      );

      await manager.processResult(
        event: LevelResultEvent(finalResult),
        levelData: levelDef,
        highestCombo: 3,
        largestBlast: 6,
      );

      expect(manager.currentLevelData, isNotNull);
      expect(manager.currentLevelData!.goals.length, 2);
      expect(manager.currentLevelData!.goals[0].color, BlockColor.purple);
      expect(manager.currentLevelData!.goals[0].targetAmount, 25);
      expect(manager.currentFinalResult, isNotNull);
      expect(manager.currentFinalResult!.incompleteGoals[0].currentAmount, 17);
      expect(manager.currentFinalResult!.incompleteGoals[1].currentAmount, 1);

      // Verify reset clears them
      manager.reset();
      expect(manager.currentLevelData, isNull);
      expect(manager.currentFinalResult, isNull);
    });

    testWidgets('2. AppRoutes.generateRoute parses Map arguments with initialBooster for gameplay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );

      final route = AppRoutes.generateRoute(
        const RouteSettings(
          name: AppRoutes.gameplay,
          arguments: {
            'levelId': 'level_11',
            'initialBooster': BoosterType.extraMoves,
          },
        ),
      );

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final context = tester.element(find.byType(SizedBox));
      final widget = materialRoute.builder(context);
      expect(widget, isA<GameplayScreen>());
      final gameplayScreen = widget as GameplayScreen;
      expect(gameplayScreen.levelId, 'level_11');
      expect(gameplayScreen.initialBooster, BoosterType.extraMoves);
    });

    testWidgets('3. AppRoutes.generateRoute handles standard String arguments seamlessly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );

      final route = AppRoutes.generateRoute(
        const RouteSettings(
          name: AppRoutes.gameplay,
          arguments: 'level_5',
        ),
      );

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final context = tester.element(find.byType(SizedBox));
      final widget = materialRoute.builder(context);
      expect(widget, isA<GameplayScreen>());
      final gameplayScreen = widget as GameplayScreen;
      expect(gameplayScreen.levelId, 'level_5');
      expect(gameplayScreen.initialBooster, isNull);
    });
  });
}
