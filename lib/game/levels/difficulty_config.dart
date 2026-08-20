class DifficultyConfig {
  final int? colorCount;
  final double? spawnDifficulty;
  final double? specialFrequency;
  final double? cascadeFrequency;

  const DifficultyConfig({
    this.colorCount,
    this.spawnDifficulty,
    this.specialFrequency,
    this.cascadeFrequency,
  });

  factory DifficultyConfig.fromJson(Map<String, dynamic> json) {
    return DifficultyConfig(
      colorCount: json['colorCount'] as int?,
      spawnDifficulty: (json['spawnDifficulty'] as num?)?.toDouble(),
      specialFrequency: (json['specialFrequency'] as num?)?.toDouble(),
      cascadeFrequency: (json['cascadeFrequency'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (colorCount != null) 'colorCount': colorCount,
      if (spawnDifficulty != null) 'spawnDifficulty': spawnDifficulty,
      if (specialFrequency != null) 'specialFrequency': specialFrequency,
      if (cascadeFrequency != null) 'cascadeFrequency': cascadeFrequency,
    };
  }
}
