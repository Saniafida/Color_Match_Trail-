import 'game_status.dart';
import 'level_result_reason.dart';
import '../goals/goal_state.dart';

class FinalLevelResult {
  final GameStatus status; // won or lost
  final LevelResultReason reason;
  final int finalScore;
  final int remainingMoves;
  final int remainingTime;
  final List<GoalState> completedGoals;
  final List<GoalState> incompleteGoals;

  const FinalLevelResult({
    required this.status,
    required this.reason,
    required this.finalScore,
    required this.remainingMoves,
    required this.remainingTime,
    this.completedGoals = const [],
    this.incompleteGoals = const [],
  });
}
