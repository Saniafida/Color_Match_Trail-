import '../balance/difficulty_tier.dart';

class LevelValidationReport {
  final String levelId;
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final DifficultyTier difficulty;
  final double estimatedComplexity;
  final List<String> missingAssets;

  const LevelValidationReport({
    required this.levelId,
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.difficulty = DifficultyTier.normal,
    this.estimatedComplexity = 1.0,
    this.missingAssets = const [],
  });

  factory LevelValidationReport.valid(String levelId, {DifficultyTier difficulty = DifficultyTier.normal, double complexity = 1.0}) {
    return LevelValidationReport(
      levelId: levelId,
      isValid: true,
      difficulty: difficulty,
      estimatedComplexity: complexity,
    );
  }

  factory LevelValidationReport.invalid(String levelId, {required List<String> errors, List<String> warnings = const [], List<String> missingAssets = const []}) {
    return LevelValidationReport(
      levelId: levelId,
      isValid: false,
      errors: errors,
      warnings: warnings,
      missingAssets: missingAssets,
    );
  }
}
