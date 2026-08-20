import '../moves/move_controller.dart';
import '../../core/services/timer/timer_controller.dart';
import '../../core/services/timer/timer_state.dart';
import '../../models/level_rules.dart';
import 'level_result_reason.dart';

class LoseConditionController {
  final MoveController moveController;
  final TimerController timerController;
  final LoseRule loseRule;

  const LoseConditionController({
    required this.moveController,
    required this.timerController,
    required this.loseRule,
  });

  bool get isLoseConditionMet {
    return determineLoseReason() != null;
  }

  LevelResultReason? determineLoseReason() {
    final movesExhausted = !moveController.hasMoves;
    final timeExhausted = timerController.state.remainingSeconds <= 0 && timerController.state.mode == TimerMode.countdown;

    switch (loseRule) {
      case LoseRule.movesExhausted:
        if (movesExhausted) return LevelResultReason.movesExhausted;
        break;
      case LoseRule.timeExpired:
        if (timeExhausted) return LevelResultReason.timeExpired;
        break;
      case LoseRule.movesOrTimeExhausted:
        if (movesExhausted && timeExhausted) return LevelResultReason.movesAndTimeExhausted;
        if (movesExhausted) return LevelResultReason.movesExhausted;
        if (timeExhausted) return LevelResultReason.timeExpired;
        break;
    }
    return null;
  }
}
