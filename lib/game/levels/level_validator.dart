import '../../models/level.dart';
import '../../models/data/level_definition.dart';
import '../balance/difficulty_tier.dart';
import 'level_validation_result.dart';
import 'level_validation_report.dart';

class LevelValidator {
  const LevelValidator();

  /// Validates a domain LevelDefinition object
  LevelValidationResult validate(LevelDefinition level) {
    List<String> errors = [];
    List<String> warnings = [];

    if (level.id <= 0) {
      errors.add('Level ID must be greater than 0.');
    }

    if (level.boardConfig.rows <= 0) {
      errors.add('Board rows must be greater than 0.');
    }

    if (level.boardConfig.columns <= 0) {
      errors.add('Board columns must be greater than 0.');
    }

    if (level.colorConfig == null || level.colorConfig!.availableColors.length < 3) {
      errors.add('Level must configure at least 3 available colors.');
    }

    if (level.movesLimit != null && level.movesLimit! <= 0) {
      errors.add('movesLimit must be greater than 0 if provided.');
    }

    if (level.timeLimit != null && level.timeLimit! <= 0) {
      errors.add('timeLimit must be greater than 0 if provided.');
    }

    if (level.goals.isEmpty && level.movesLimit == null && level.timeLimit == null) {
      warnings.add('Level has no goals, no moves limit, and no time limit.');
    }

    // Special validation
    if (level.specialConfig != null && level.specialConfig!.enabled) {
      if (level.specialConfig!.allowedSpecialTypes.isEmpty) {
        warnings.add('Specials are enabled but no special types are allowed.');
      }
    }

    // Booster validation
    if (level.boosterConfig != null && level.boosterConfig!.allowedBoosters.isEmpty) {
      warnings.add('Booster config exists but no boosters are allowed.');
    }

    if (errors.isNotEmpty) {
      return LevelValidationResult.invalid(errors, warnings);
    }

    return LevelValidationResult.valid();
  }

  /// Deep validation of LevelDefinitionData (JSON data definition)
  LevelValidationReport validateData(LevelDefinitionData level) {
    final List<String> errors = [];
    final List<String> warnings = [];
    final List<String> missingAssets = [];

    if (level.levelId.isEmpty) {
      errors.add('Level ID cannot be empty.');
    }

    if (level.boardRows <= 0 || level.boardRows > 12) {
      errors.add('Board rows must be between 1 and 12 (was ${level.boardRows}).');
    }

    if (level.boardColumns <= 0 || level.boardColumns > 12) {
      errors.add('Board columns must be between 1 and 12 (was ${level.boardColumns}).');
    }

    if (level.moveLimit <= 0) {
      errors.add('Move limit must be greater than 0 (was ${level.moveLimit}).');
    }

    if (level.goals.isEmpty) {
      warnings.add('Level has no configured goals.');
    } else {
      for (final goal in level.goals) {
        if (goal.targetAmount <= 0) {
          errors.add('Goal ${goal.id} has non-positive target amount (${goal.targetAmount}).');
        }
      }
    }

    if (level.scoreTarget <= 0) {
      warnings.add('Score target is 0 or negative.');
    }

    if (level.starThresholds.length < 3) {
      warnings.add('Star thresholds should define at least 3 milestones.');
    }

    final tier = DifficultyTier.fromString(level.difficulty);

    return LevelValidationReport(
      levelId: level.levelId,
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      difficulty: tier,
      estimatedComplexity: tier.complexityWeight,
      missingAssets: missingAssets,
    );
  }

  /// Batch validation of all campaign levels
  List<LevelValidationReport> validateCampaign(List<LevelDefinitionData> levels) {
    final Set<String> seenIds = {};
    final List<LevelValidationReport> reports = [];

    for (final lvl in levels) {
      final report = validateData(lvl);
      final errors = List<String>.from(report.errors);

      // Check duplicate ID
      if (seenIds.contains(lvl.levelId)) {
        errors.add('Duplicate Level ID: "${lvl.levelId}".');
      }
      seenIds.add(lvl.levelId);

      reports.add(LevelValidationReport(
        levelId: report.levelId,
        isValid: errors.isEmpty,
        errors: errors,
        warnings: report.warnings,
        difficulty: report.difficulty,
        estimatedComplexity: report.estimatedComplexity,
        missingAssets: report.missingAssets,
      ));
    }

    return reports;
  }
}
