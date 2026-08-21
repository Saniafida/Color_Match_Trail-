class LevelProgress {
  final String levelId;
  final bool unlocked;
  final bool completed;
  final int bestScore;
  final int bestStars;
  final int attemptCount;
  final DateTime? firstCompleted;
  final DateTime? lastPlayed;
  final int bestMoves;
  final int highestCombo;

  const LevelProgress({
    required this.levelId,
    required this.unlocked,
    required this.completed,
    required this.bestScore,
    required this.bestStars,
    this.attemptCount = 0,
    this.firstCompleted,
    this.lastPlayed,
    this.bestMoves = 0,
    this.highestCombo = 0,
  });

  /// Alias for bestStars to preserve backwards compatibility
  int get stars => bestStars;

  /// Alias for bestScore to preserve backwards compatibility
  int get highestScore => bestScore;

  /// Alias for firstCompleted
  DateTime? get completedAt => firstCompleted;

  factory LevelProgress.locked(String id) {
    return LevelProgress(
      levelId: id,
      unlocked: false,
      completed: false,
      bestScore: 0,
      bestStars: 0,
      attemptCount: 0,
      bestMoves: 0,
      highestCombo: 0,
    );
  }

  factory LevelProgress.unlocked(String id) {
    return LevelProgress(
      levelId: id,
      unlocked: true,
      completed: false,
      bestScore: 0,
      bestStars: 0,
      attemptCount: 0,
      bestMoves: 0,
      highestCombo: 0,
    );
  }

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    final starsVal = json['bestStars'] as int? ?? json['stars'] as int? ?? 0;
    final scoreVal = json['bestScore'] as int? ?? json['highestScore'] as int? ?? 0;

    DateTime? firstComp;
    if (json['firstCompleted'] != null) {
      firstComp = DateTime.tryParse(json['firstCompleted'] as String);
    } else if (json['completedAt'] != null) {
      firstComp = DateTime.tryParse(json['completedAt'] as String);
    }

    DateTime? lastPlay;
    if (json['lastPlayed'] != null) {
      lastPlay = DateTime.tryParse(json['lastPlayed'] as String);
    }

    return LevelProgress(
      levelId: json['levelId'] as String? ?? '',
      unlocked: json['unlocked'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      bestScore: scoreVal,
      bestStars: starsVal,
      attemptCount: json['attemptCount'] as int? ?? 0,
      firstCompleted: firstComp,
      lastPlayed: lastPlay,
      bestMoves: json['bestMoves'] as int? ?? 0,
      highestCombo: json['highestCombo'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'unlocked': unlocked,
      'completed': completed,
      'bestScore': bestScore,
      'bestStars': bestStars,
      'stars': bestStars, // redundancy for backwards compatibility
      'attemptCount': attemptCount,
      if (firstCompleted != null) 'firstCompleted': firstCompleted!.toIso8601String(),
      if (lastPlayed != null) 'lastPlayed': lastPlayed!.toIso8601String(),
      'bestMoves': bestMoves,
      'highestCombo': highestCombo,
    };
  }

  LevelProgress copyWith({
    bool? unlocked,
    bool? completed,
    int? bestScore,
    int? bestStars,
    int? stars,
    int? highestScore,
    int? attemptCount,
    DateTime? firstCompleted,
    DateTime? completedAt,
    DateTime? lastPlayed,
    int? bestMoves,
    int? highestCombo,
  }) {
    return LevelProgress(
      levelId: levelId,
      unlocked: unlocked ?? this.unlocked,
      completed: completed ?? this.completed,
      bestScore: bestScore ?? highestScore ?? this.bestScore,
      bestStars: bestStars ?? stars ?? this.bestStars,
      attemptCount: attemptCount ?? this.attemptCount,
      firstCompleted: firstCompleted ?? completedAt ?? this.firstCompleted,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      bestMoves: bestMoves ?? this.bestMoves,
      highestCombo: highestCombo ?? this.highestCombo,
    );
  }
}
