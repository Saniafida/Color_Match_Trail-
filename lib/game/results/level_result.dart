class LevelResult {
  final String levelId;
  final bool completed;
  final int finalScore;
  final int stars;
  final int movesUsed;
  final int movesRemaining;
  final int highestCombo;
  final int largestBlast;
  final int goalsCompleted;
  final int bonusScore;
  final String? rewardId;
  final DateTime completedAt;

  const LevelResult({
    required this.levelId,
    required this.completed,
    required this.finalScore,
    required this.stars,
    required this.movesUsed,
    required this.movesRemaining,
    required this.highestCombo,
    required this.largestBlast,
    required this.goalsCompleted,
    required this.bonusScore,
    this.rewardId,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'completed': completed,
      'finalScore': finalScore,
      'stars': stars,
      'movesUsed': movesUsed,
      'movesRemaining': movesRemaining,
      'highestCombo': highestCombo,
      'largestBlast': largestBlast,
      'goalsCompleted': goalsCompleted,
      'bonusScore': bonusScore,
      'rewardId': rewardId,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory LevelResult.fromJson(Map<String, dynamic> json) {
    return LevelResult(
      levelId: json['levelId'] as String,
      completed: json['completed'] as bool? ?? false,
      finalScore: json['finalScore'] as int? ?? 0,
      stars: json['stars'] as int? ?? 0,
      movesUsed: json['movesUsed'] as int? ?? 0,
      movesRemaining: json['movesRemaining'] as int? ?? 0,
      highestCombo: json['highestCombo'] as int? ?? 0,
      largestBlast: json['largestBlast'] as int? ?? 0,
      goalsCompleted: json['goalsCompleted'] as int? ?? 0,
      bonusScore: json['bonusScore'] as int? ?? 0,
      rewardId: json['rewardId'] as String?,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : DateTime.now(),
    );
  }
}
