class ScoreState {
  final int currentScore;
  final int highScore;
  final int lastAddedScore;
  final int comboLevel;
  final int cascadeLevel;

  const ScoreState({
    this.currentScore = 0,
    this.highScore = 0,
    this.lastAddedScore = 0,
    this.comboLevel = 0,
    this.cascadeLevel = 0,
  });

  ScoreState copyWith({
    int? currentScore,
    int? highScore,
    int? lastAddedScore,
    int? comboLevel,
    int? cascadeLevel,
  }) {
    return ScoreState(
      currentScore: currentScore ?? this.currentScore,
      highScore: highScore ?? this.highScore,
      lastAddedScore: lastAddedScore ?? this.lastAddedScore,
      comboLevel: comboLevel ?? this.comboLevel,
      cascadeLevel: cascadeLevel ?? this.cascadeLevel,
    );
  }
}
