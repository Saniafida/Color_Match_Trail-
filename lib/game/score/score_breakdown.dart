class ScoreBreakdown {
  final int destroyedBlocks;
  final int baseScore;
  final double connectionMultiplier;
  final double cascadeMultiplier;
  final double comboMultiplier;
  final int finalScore;
  final int cascadeLevel;
  final int comboLevel;

  const ScoreBreakdown({
    required this.destroyedBlocks,
    required this.baseScore,
    required this.connectionMultiplier,
    required this.cascadeMultiplier,
    required this.comboMultiplier,
    required this.finalScore,
    required this.cascadeLevel,
    required this.comboLevel,
  });
}
