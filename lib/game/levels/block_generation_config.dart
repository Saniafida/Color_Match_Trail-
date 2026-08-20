class BlockGenerationConfig {
  final int? initialBlockCount;
  final bool allowEmptyCells;
  final bool allowInitialMatches;

  const BlockGenerationConfig({
    this.initialBlockCount,
    this.allowEmptyCells = false,
    this.allowInitialMatches = false,
  });

  factory BlockGenerationConfig.fromJson(Map<String, dynamic> json) {
    return BlockGenerationConfig(
      initialBlockCount: json['initialBlockCount'] as int?,
      allowEmptyCells: json['allowEmptyCells'] as bool? ?? false,
      allowInitialMatches: json['allowInitialMatches'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (initialBlockCount != null) 'initialBlockCount': initialBlockCount,
      'allowEmptyCells': allowEmptyCells,
      'allowInitialMatches': allowInitialMatches,
    };
  }
}
