import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/level_result/level_result_system.dart';
import 'package:color_match_trail/game/moves/moves.dart';
import 'package:color_match_trail/core/services/timer/timer.dart';
import 'package:color_match_trail/game/goals/goal_controller.dart';
import 'package:color_match_trail/game/score/score_controller.dart';
import 'package:color_match_trail/game/combo/combo_controller.dart';
import 'package:color_match_trail/game/blast/blast_result.dart';
import 'package:color_match_trail/core/storage/storage.dart';
import 'package:color_match_trail/game/levels/board_config.dart';

class MockGameStorage implements GameStorage {
  @override Future<void> init() async {}
  @override Future<int> getCoins() async => 0;
  @override Future<void> setCoins(int coins) async {}
  @override Future<int> getLives() async => 0;
  @override Future<void> setLives(int lives) async {}
  @override Future<int> getGems() async => 0;
  @override Future<void> setGems(int gems) async {}
  @override
  Future<bool> getAudioEnabled() async => true;
  @override
  Future<void> setAudioEnabled(bool enabled) async {}

  @override
  Future<String?> getBoosterInventoryRaw() async => null;
  @override
  Future<void> setBoosterInventoryRaw(String rawJson) async {}
}

void main() {
  group('LevelResultController Tests', () {
    late LevelResultController resultController;
    late MoveController moveController;
    late TimerController timerController;
    late GoalController goalController;
    late ScoreController scoreController;
    late ComboController comboController;
    late LevelDefinition levelDef;

    setUp(() {
      comboController = ComboController();
      scoreController = ScoreController(comboController: comboController);
      scoreController.init(0);
      goalController = GoalController();
      moveController = MoveController();
      timerController = TimerController();

      levelDef = const LevelDefinition(
        id: 1,
        boardConfig: BoardConfig(rows: 5, columns: 5),
        movesLimit: 5,
        timeLimit: null,
      );

      moveController.initialize(levelDef.movesLimit);
      timerController.initialize(levelDef.timeLimit);
      goalController.initialize([
        const GoalDefinition(
          id: 'goal_1',
          type: GoalType.clearColor,
          targetAmount: 3,
          color: BlockColor.red,
        )
      ]);

      resultController = LevelResultController(
        winCondition: WinConditionController(
          goalController: goalController,
          winRule: levelDef.winRule,
        ),
        loseCondition: LoseConditionController(
          moveController: moveController,
          timerController: timerController,
          loseRule: levelDef.loseRule,
        ),
        moveController: moveController,
        timerController: timerController,
        goalController: goalController,
        scoreController: scoreController,
        levelDefinition: levelDef,
      );
    });

    test('TEST 1: Win priority on last move', () {
      resultController.startGame();
      
      // Consume all moves
      for (int i = 0; i < 5; i++) {
        moveController.consumeMove();
      }
      expect(moveController.currentMoves, 0);

      // Now complete the goal
      goalController.onBlastResult(const BlastResult(
        success: true,
        destroyedCount: 3,
        color: BlockColor.red,
        destroyedPositions: [],
        source: DestructionSource.playerMatch,
      ));

      resultController.evaluate();

      expect(resultController.status, GameStatus.won);
    });

    test('TEST 2: Lose when moves exhausted and goals incomplete', () {
      resultController.startGame();
      
      // Consume all moves
      for (int i = 0; i < 5; i++) {
        moveController.consumeMove();
      }
      expect(moveController.currentMoves, 0);

      resultController.evaluate();

      expect(resultController.status, GameStatus.lost);
    });

    test('TEST 3: Resolving state prevents evaluate', () {
      resultController.startGame();
      resultController.setResolving(true);
      
      for (int i = 0; i < 5; i++) {
        moveController.consumeMove();
      }

      resultController.evaluate();
      expect(resultController.status, GameStatus.resolving);
      
      resultController.setResolving(false); // Should evaluate internally
      expect(resultController.status, GameStatus.lost);
    });
    
    test('TEST 4: Duplicate Result Protection', () {
      resultController.startGame();
      
      for (int i = 0; i < 5; i++) {
        moveController.consumeMove();
      }
      resultController.evaluate(); // Lost
      
      expect(resultController.status, GameStatus.lost);
      
      // Simulate completing goal after lost
      goalController.onBlastResult(const BlastResult(
        success: true,
        destroyedCount: 3,
        color: BlockColor.red,
        destroyedPositions: [],
        source: DestructionSource.playerMatch,
      ));
      resultController.evaluate(); 
      
      // Should STILL be lost, duplicate protection
      expect(resultController.status, GameStatus.lost);
    });
  });
}
