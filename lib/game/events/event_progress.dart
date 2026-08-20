class EventProgress {
  final String eventId;
  final int currentValue;
  final int targetValue;
  final bool completed;
  final bool rewardClaimed;

  const EventProgress({
    required this.eventId,
    this.currentValue = 0,
    required this.targetValue,
    this.completed = false,
    this.rewardClaimed = false,
  });

  EventProgress copyWith({
    int? currentValue,
    bool? completed,
    bool? rewardClaimed,
  }) {
    return EventProgress(
      eventId: eventId,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue,
      completed: completed ?? this.completed,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'completed': completed,
      'rewardClaimed': rewardClaimed,
    };
  }

  factory EventProgress.fromJson(Map<String, dynamic> json) {
    return EventProgress(
      eventId: json['eventId'] as String,
      currentValue: json['currentValue'] as int? ?? 0,
      targetValue: json['targetValue'] as int,
      completed: json['completed'] as bool? ?? false,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
    );
  }
}
