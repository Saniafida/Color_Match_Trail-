class PlayerStatistics {
  final int levelsCompleted;
  final int totalStars;
  final int highestScore;
  final int highestCombo;
  final int highestCascade;
  final int totalBlocksCleared;
  final int totalBoostersUsed;
  final int totalDailyChallenges;
  final int totalEventsCompleted;
  final int totalPlayTime;

  const PlayerStatistics({
    this.levelsCompleted = 0,
    this.totalStars = 0,
    this.highestScore = 0,
    this.highestCombo = 0,
    this.highestCascade = 0,
    this.totalBlocksCleared = 0,
    this.totalBoostersUsed = 0,
    this.totalDailyChallenges = 0,
    this.totalEventsCompleted = 0,
    this.totalPlayTime = 0,
  });

  PlayerStatistics copyWith({
    int? levelsCompleted,
    int? totalStars,
    int? highestScore,
    int? highestCombo,
    int? highestCascade,
    int? totalBlocksCleared,
    int? totalBoostersUsed,
    int? totalDailyChallenges,
    int? totalEventsCompleted,
    int? totalPlayTime,
  }) {
    return PlayerStatistics(
      levelsCompleted: levelsCompleted ?? this.levelsCompleted,
      totalStars: totalStars ?? this.totalStars,
      highestScore: highestScore ?? this.highestScore,
      highestCombo: highestCombo ?? this.highestCombo,
      highestCascade: highestCascade ?? this.highestCascade,
      totalBlocksCleared: totalBlocksCleared ?? this.totalBlocksCleared,
      totalBoostersUsed: totalBoostersUsed ?? this.totalBoostersUsed,
      totalDailyChallenges: totalDailyChallenges ?? this.totalDailyChallenges,
      totalEventsCompleted: totalEventsCompleted ?? this.totalEventsCompleted,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelsCompleted': levelsCompleted,
      'totalStars': totalStars,
      'highestScore': highestScore,
      'highestCombo': highestCombo,
      'highestCascade': highestCascade,
      'totalBlocksCleared': totalBlocksCleared,
      'totalBoostersUsed': totalBoostersUsed,
      'totalDailyChallenges': totalDailyChallenges,
      'totalEventsCompleted': totalEventsCompleted,
      'totalPlayTime': totalPlayTime,
    };
  }

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) {
    return PlayerStatistics(
      levelsCompleted: json['levelsCompleted'] as int? ?? 0,
      totalStars: json['totalStars'] as int? ?? 0,
      highestScore: json['highestScore'] as int? ?? 0,
      highestCombo: json['highestCombo'] as int? ?? 0,
      highestCascade: json['highestCascade'] as int? ?? 0,
      totalBlocksCleared: json['totalBlocksCleared'] as int? ?? 0,
      totalBoostersUsed: json['totalBoostersUsed'] as int? ?? 0,
      totalDailyChallenges: json['totalDailyChallenges'] as int? ?? 0,
      totalEventsCompleted: json['totalEventsCompleted'] as int? ?? 0,
      totalPlayTime: json['totalPlayTime'] as int? ?? 0,
    );
  }
}
