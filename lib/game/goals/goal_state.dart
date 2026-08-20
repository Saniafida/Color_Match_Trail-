import 'dart:math' as math;

class GoalState {
  final String goalId;
  final int currentAmount;
  final int targetAmount;
  final bool completed;
  final bool isOptional;

  const GoalState({
    required this.goalId,
    required this.currentAmount,
    required this.targetAmount,
    required this.completed,
    required this.isOptional,
  });

  double get completionProgress => math.min(currentAmount / targetAmount, 1.0);

  GoalState copyWith({
    String? goalId,
    int? currentAmount,
    int? targetAmount,
    bool? completed,
    bool? isOptional,
  }) {
    return GoalState(
      goalId: goalId ?? this.goalId,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      completed: completed ?? this.completed,
      isOptional: isOptional ?? this.isOptional,
    );
  }
}
