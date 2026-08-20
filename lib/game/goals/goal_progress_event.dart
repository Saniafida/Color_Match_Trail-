import 'goal_event_source.dart';

class GoalProgressEvent {
  final String goalId;
  final int previousAmount;
  final int newAmount;
  final int amountAdded;
  final GoalEventSource source;
  final bool completed;

  const GoalProgressEvent({
    required this.goalId,
    required this.previousAmount,
    required this.newAmount,
    required this.amountAdded,
    required this.source,
    required this.completed,
  });
}
