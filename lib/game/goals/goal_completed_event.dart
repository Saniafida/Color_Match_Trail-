import '../../models/goal.dart';

class GoalCompletedEvent {
  final String goalId;
  final GoalType goalType;
  final int finalAmount;
  final int targetAmount;

  const GoalCompletedEvent({
    required this.goalId,
    required this.goalType,
    required this.finalAmount,
    required this.targetAmount,
  });
}
