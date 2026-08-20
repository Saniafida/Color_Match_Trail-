class AchievementProgress {
  final String achievementId;
  final int currentValue;
  final int targetValue;
  final bool unlocked;
  final DateTime? unlockedAt;
  final bool rewardClaimed;

  const AchievementProgress({
    required this.achievementId,
    required this.currentValue,
    required this.targetValue,
    required this.unlocked,
    this.unlockedAt,
    required this.rewardClaimed,
  });

  AchievementProgress copyWith({
    int? currentValue,
    int? targetValue,
    bool? unlocked,
    DateTime? unlockedAt,
    bool? rewardClaimed,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'rewardClaimed': rewardClaimed,
    };
  }

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievementId'] as String,
      currentValue: json['currentValue'] as int? ?? 0,
      targetValue: json['targetValue'] as int? ?? 1,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
    );
  }
}
