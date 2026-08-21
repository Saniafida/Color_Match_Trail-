class DifficultyDefinition {
  final String tier; // 'easy', 'normal', 'hard', 'expert'
  final int minColors;
  final int maxColors;
  final int minMoves;
  final int maxMoves;
  final int baseScoreMultiplier;
  final double estimatedClearRate;
  final double complexityWeight;

  const DifficultyDefinition({
    required this.tier,
    this.minColors = 3,
    this.maxColors = 5,
    this.minMoves = 15,
    this.maxMoves = 35,
    this.baseScoreMultiplier = 1,
    this.estimatedClearRate = 0.8,
    this.complexityWeight = 1.0,
  });

  factory DifficultyDefinition.fromJson(Map<String, dynamic> json) {
    return DifficultyDefinition(
      tier: json['tier'] as String? ?? 'normal',
      minColors: json['minColors'] as int? ?? 3,
      maxColors: json['maxColors'] as int? ?? 5,
      minMoves: json['minMoves'] as int? ?? 15,
      maxMoves: json['maxMoves'] as int? ?? 35,
      baseScoreMultiplier: json['baseScoreMultiplier'] as int? ?? 1,
      estimatedClearRate: (json['estimatedClearRate'] as num?)?.toDouble() ?? 0.8,
      complexityWeight: (json['complexityWeight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'minColors': minColors,
      'maxColors': maxColors,
      'minMoves': minMoves,
      'maxMoves': maxMoves,
      'baseScoreMultiplier': baseScoreMultiplier,
      'estimatedClearRate': estimatedClearRate,
      'complexityWeight': complexityWeight,
    };
  }
}
