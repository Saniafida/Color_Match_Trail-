class DailyChallengeProgress {
  final String challengeId;
  final int currentValue;
  final int currentValue2;
  final int targetValue;
  final int targetValue2;
  final bool completed;
  final bool rewardClaimed;

  const DailyChallengeProgress({
    required this.challengeId,
    this.currentValue = 0,
    this.currentValue2 = 0,
    required this.targetValue,
    int? targetValue2,
    this.completed = false,
    this.rewardClaimed = false,
  }) : targetValue2 = targetValue2 ?? targetValue;

  DailyChallengeProgress copyWith({
    int? currentValue,
    int? currentValue2,
    int? targetValue,
    int? targetValue2,
    bool? completed,
    bool? rewardClaimed,
  }) {
    return DailyChallengeProgress(
      challengeId: challengeId,
      currentValue: currentValue ?? this.currentValue,
      currentValue2: currentValue2 ?? this.currentValue2,
      targetValue: targetValue ?? this.targetValue,
      targetValue2: targetValue2 ?? this.targetValue2,
      completed: completed ?? this.completed,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'currentValue': currentValue,
      'currentValue2': currentValue2,
      'targetValue': targetValue,
      'targetValue2': targetValue2,
      'completed': completed,
      'rewardClaimed': rewardClaimed,
    };
  }

  factory DailyChallengeProgress.fromJson(Map<String, dynamic> json) {
    return DailyChallengeProgress(
      challengeId: json['challengeId'] as String,
      currentValue: json['currentValue'] as int? ?? 0,
      currentValue2: json['currentValue2'] as int? ?? 0,
      targetValue: json['targetValue'] as int? ?? 30,
      targetValue2: json['targetValue2'] as int? ?? json['targetValue'] as int? ?? 30,
      completed: json['completed'] as bool? ?? false,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
    );
  }
}

