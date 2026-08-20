class DailyChallengeProgress {
  final String challengeId;
  final int currentValue;
  final int targetValue;
  final bool completed;
  final bool rewardClaimed;

  const DailyChallengeProgress({
    required this.challengeId,
    this.currentValue = 0,
    required this.targetValue,
    this.completed = false,
    this.rewardClaimed = false,
  });

  DailyChallengeProgress copyWith({
    int? currentValue,
    bool? completed,
    bool? rewardClaimed,
  }) {
    return DailyChallengeProgress(
      challengeId: challengeId,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue,
      completed: completed ?? this.completed,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'completed': completed,
      'rewardClaimed': rewardClaimed,
    };
  }

  factory DailyChallengeProgress.fromJson(Map<String, dynamic> json) {
    return DailyChallengeProgress(
      challengeId: json['challengeId'] as String,
      currentValue: json['currentValue'] as int,
      targetValue: json['targetValue'] as int,
      completed: json['completed'] as bool,
      rewardClaimed: json['rewardClaimed'] as bool,
    );
  }
}
