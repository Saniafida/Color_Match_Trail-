import '../../models/position.dart';

abstract class FeedbackEvent {}

class FloatingTextFeedbackEvent extends FeedbackEvent {
  final String text;
  final Position? boardPosition;

  FloatingTextFeedbackEvent({required this.text, this.boardPosition});
}

class CascadeFeedbackEvent extends FeedbackEvent {
  final int comboLevel;
  CascadeFeedbackEvent(this.comboLevel);
}

class GoalCompleteFeedbackEvent extends FeedbackEvent {
  final String goalId;
  GoalCompleteFeedbackEvent(this.goalId);
}

class LevelWinFeedbackEvent extends FeedbackEvent {
  LevelWinFeedbackEvent();
}
