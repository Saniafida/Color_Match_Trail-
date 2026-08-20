class LevelProgress {
  final String levelId;
  final bool unlocked;
  final bool completed;
  final int stars;
  final int bestScore;
  final int bestMoves;
  final int highestCombo;
  final DateTime? completedAt;

  const LevelProgress({
    required this.levelId,
    required this.unlocked,
    required this.completed,
    required this.stars,
    required this.bestScore,
    required this.bestMoves,
    required this.highestCombo,
    this.completedAt,
  });

  factory LevelProgress.locked(String id) {
    return LevelProgress(
      levelId: id,
      unlocked: false,
      completed: false,
      stars: 0,
      bestScore: 0,
      bestMoves: 0,
      highestCombo: 0,
    );
  }

  factory LevelProgress.unlocked(String id) {
    return LevelProgress(
      levelId: id,
      unlocked: true,
      completed: false,
      stars: 0,
      bestScore: 0,
      bestMoves: 0,
      highestCombo: 0,
    );
  }

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      levelId: json['levelId'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      bestMoves: json['bestMoves'] as int? ?? 0,
      highestCombo: json['highestCombo'] as int? ?? 0,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'unlocked': unlocked,
      'completed': completed,
      'stars': stars,
      'bestScore': bestScore,
      'bestMoves': bestMoves,
      'highestCombo': highestCombo,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  LevelProgress copyWith({
    bool? unlocked,
    bool? completed,
    int? stars,
    int? bestScore,
    int? bestMoves,
    int? highestCombo,
    DateTime? completedAt,
  }) {
    return LevelProgress(
      levelId: levelId,
      unlocked: unlocked ?? this.unlocked,
      completed: completed ?? this.completed,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
      bestMoves: bestMoves ?? this.bestMoves,
      highestCombo: highestCombo ?? this.highestCombo,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
