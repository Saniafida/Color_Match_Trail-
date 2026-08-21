class AchievementProgress {
  final String achievementId;
  final int currentValue;
  final int targetValue;
  final bool completed;
  final DateTime? completedAt;
  final bool rewardGranted;

  const AchievementProgress({
    required this.achievementId,
    required this.currentValue,
    required this.targetValue,
    required this.completed,
    this.completedAt,
    required this.rewardGranted,
  });

  AchievementProgress copyWith({
    int? currentValue,
    int? targetValue,
    bool? completed,
    DateTime? completedAt,
    bool? rewardGranted,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      rewardGranted: rewardGranted ?? this.rewardGranted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'rewardGranted': rewardGranted,
    };
  }

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievementId'] as String,
      currentValue: json['currentValue'] as int? ?? 0,
      targetValue: json['targetValue'] as int? ?? 1,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      rewardGranted: json['rewardGranted'] as bool? ?? false,
    );
  }
}
