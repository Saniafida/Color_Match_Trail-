import 'dart:async';
import 'package:flutter/foundation.dart';
import 'game_status.dart';
import 'level_result.dart';
import 'level_result_reason.dart';
import 'level_event.dart';
import 'win_condition_controller.dart';
import 'lose_condition_controller.dart';
import '../moves/move_controller.dart';
import '../../core/services/timer/timer_controller.dart';
import '../goals/goal_controller.dart';
import '../score/score_controller.dart';
import '../../models/level.dart';

class LevelResultController extends ChangeNotifier {
  final WinConditionController winCondition;
  final LoseConditionController loseCondition;
  final MoveController moveController;
  final TimerController timerController;
  final GoalController goalController;
  final ScoreController scoreController;
  final LevelDefinition levelDefinition;

  GameStatus _status = GameStatus.initializing;
  GameStatus get status => _status;

  final StreamController<LevelResultEvent> _resultController = StreamController<LevelResultEvent>.broadcast(sync: true);
  Stream<LevelResultEvent> get onLevelResult => _resultController.stream;

  final StreamController<LevelStartedEvent> _startedController = StreamController<LevelStartedEvent>.broadcast(sync: true);
  Stream<LevelStartedEvent> get onLevelStarted => _startedController.stream;

  final StreamController<LevelPausedEvent> _pausedController = StreamController<LevelPausedEvent>.broadcast(sync: true);
  Stream<LevelPausedEvent> get onLevelPaused => _pausedController.stream;

  final StreamController<LevelResumedEvent> _resumedController = StreamController<LevelResumedEvent>.broadcast(sync: true);
  Stream<LevelResumedEvent> get onLevelResumed => _resumedController.stream;

  final StreamController<LevelRestartedEvent> _restartedController = StreamController<LevelRestartedEvent>.broadcast(sync: true);
  Stream<LevelRestartedEvent> get onLevelRestarted => _restartedController.stream;

  bool get isResolving => _status == GameStatus.resolving;
  bool get hasEnded => _status == GameStatus.won || _status == GameStatus.lost || _status == GameStatus.completed;

  LevelResultController({
    required this.winCondition,
    required this.loseCondition,
    required this.moveController,
    required this.timerController,
    required this.goalController,
    required this.scoreController,
    required this.levelDefinition,
  });

  void startGame() {
    if (_status != GameStatus.initializing && _status != GameStatus.restarting) return;
    
    _status = GameStatus.playing;
    timerController.start();
    
    _startedController.add(LevelStartedEvent(
      levelId: levelDefinition.id,
      startingMoves: levelDefinition.movesLimit,
      startingTime: levelDefinition.timeLimit,
      goals: levelDefinition.goals,
    ));
    notifyListeners();
  }

  void pauseGame() {
    if (_status != GameStatus.playing) return;
    
    _status = GameStatus.paused;
    timerController.pause();
    
    _pausedController.add(LevelPausedEvent(
      levelId: levelDefinition.id,
      remainingMoves: moveController.currentMoves,
      remainingTime: timerController.state.remainingSeconds,
    ));
    notifyListeners();
  }

  void resumeGame() {
    if (_status != GameStatus.paused) return;
    
    _status = GameStatus.playing;
    timerController.resume();
    
    _resumedController.add(LevelResumedEvent(
      levelId: levelDefinition.id,
      remainingMoves: moveController.currentMoves,
      remainingTime: timerController.state.remainingSeconds,
    ));
    notifyListeners();
  }

  void setResolving(bool resolving) {
    if (hasEnded) return;
    
    if (resolving) {
      _status = GameStatus.resolving;
    } else {
      _status = GameStatus.playing;
      evaluate(); // always evaluate after resolution is complete
    }
    notifyListeners();
  }

  void evaluate() {
    if (hasEnded || isResolving) return;

    if (winCondition.isWinConditionMet) {
      _endLevel(GameStatus.won, LevelResultReason.goalsCompleted);
      return;
    }

    if (loseCondition.isLoseConditionMet) {
      final reason = loseCondition.determineLoseReason() ?? LevelResultReason.systemError;
      _endLevel(GameStatus.lost, reason);
    }
  }

  void _endLevel(GameStatus newStatus, LevelResultReason reason) {
    _status = newStatus;
    timerController.stop();

    final result = FinalLevelResult(
      status: newStatus,
      reason: reason,
      finalScore: scoreController.state.currentScore,
      remainingMoves: moveController.currentMoves,
      remainingTime: timerController.state.remainingSeconds,
      completedGoals: goalController.states.where((s) => s.completed).toList(),
      incompleteGoals: goalController.states.where((s) => !s.completed).toList(),
    );

    _resultController.add(LevelResultEvent(result));
    notifyListeners();
  }

  void quitLevel() {
    if (hasEnded) return;
    _endLevel(GameStatus.lost, LevelResultReason.manualQuit);
  }

  void continueLevel() {
    // Only applies if the game is over and we want to extend it
    if (!hasEnded) return;
    _status = GameStatus.playing;
    notifyListeners();
  }

  void restartLevel() {
    _status = GameStatus.restarting;
    timerController.reset();
    moveController.resetMoves();
    scoreController.resetScore();
    goalController.resetGoals();
    
    _restartedController.add(LevelRestartedEvent(levelId: levelDefinition.id));
    
    startGame();
  }

  @override
  void dispose() {
    _resultController.close();
    _startedController.close();
    _pausedController.close();
    _resumedController.close();
    _restartedController.close();
    super.dispose();
  }
}
