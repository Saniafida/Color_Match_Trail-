import 'level_result.dart';
import '../../models/goal.dart';

class LevelResultEvent {
  final FinalLevelResult result;
  final DateTime timestamp;

  LevelResultEvent(this.result) : timestamp = DateTime.now();
}

class LevelStartedEvent {
  final int levelId;
  final int? startingMoves;
  final int? startingTime;
  final List<GoalDefinition> goals;

  const LevelStartedEvent({
    required this.levelId,
    this.startingMoves,
    this.startingTime,
    required this.goals,
  });
}

class LevelPausedEvent {
  final int levelId;
  final int remainingMoves;
  final int remainingTime;

  const LevelPausedEvent({
    required this.levelId,
    required this.remainingMoves,
    required this.remainingTime,
  });
}

class LevelResumedEvent {
  final int levelId;
  final int remainingMoves;
  final int remainingTime;

  const LevelResumedEvent({
    required this.levelId,
    required this.remainingMoves,
    required this.remainingTime,
  });
}

class LevelRestartedEvent {
  final int levelId;

  const LevelRestartedEvent({
    required this.levelId,
  });
}
