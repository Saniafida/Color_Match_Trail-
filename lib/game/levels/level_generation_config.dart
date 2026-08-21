import '../balance/difficulty_tier.dart';

class LevelGenerationConfig {
  final String templateName;
  final int boardRows;
  final int boardColumns;
  final int colorCount;
  final int moveLimit;
  final DifficultyTier difficultyTier;
  final int seed;

  const LevelGenerationConfig({
    required this.templateName,
    required this.boardRows,
    required this.boardColumns,
    required this.colorCount,
    required this.moveLimit,
    required this.difficultyTier,
    required this.seed,
  });

  factory LevelGenerationConfig.fromJson(Map<String, dynamic> json) {
    return LevelGenerationConfig(
      templateName: json['templateName'] as String? ?? 'basic',
      boardRows: json['boardRows'] as int? ?? 6,
      boardColumns: json['boardColumns'] as int? ?? 6,
      colorCount: json['colorCount'] as int? ?? 4,
      moveLimit: json['moveLimit'] as int? ?? 25,
      difficultyTier: DifficultyTier.fromString(json['difficulty'] as String?),
      seed: json['seed'] as int? ?? 42,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateName': templateName,
      'boardRows': boardRows,
      'boardColumns': boardColumns,
      'colorCount': colorCount,
      'moveLimit': moveLimit,
      'difficulty': difficultyTier.name,
      'seed': seed,
    };
  }
}
