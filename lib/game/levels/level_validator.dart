import '../../models/level.dart';
import 'level_validation_result.dart';

class LevelValidator {
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
}
