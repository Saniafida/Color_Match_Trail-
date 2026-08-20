import '../../models/data/level_definition.dart';
import '../../models/data/challenge_definition.dart';
import '../../game/events/event_definition.dart';
import '../../game/shop/shop_item_definition.dart';

class GameDataValidationResult {
  final List<String> warnings;
  final List<String> errors;

  const GameDataValidationResult({
    this.warnings = const [],
    this.errors = const [],
  });

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() {
    final buf = StringBuffer('GameDataValidationResult:\n');
    for (final e in errors) {
      buf.writeln('  ❌ ERROR: $e');
    }
    for (final w in warnings) {
      buf.writeln('  ⚠️  WARN: $w');
    }
    if (isValid && !hasWarnings) {
      buf.writeln('  ✅ All data valid.');
    }
    return buf.toString();
  }
}

class GameDataValidator {
  GameDataValidationResult validateLevels(List<LevelDefinitionData> levels) {
    final warnings = <String>[];
    final errors = <String>[];
    final seenIds = <String>{};

    for (final level in levels) {
      if (!seenIds.add(level.levelId)) {
        errors.add('Duplicate level ID: ${level.levelId}');
      }
      if (level.boardRows <= 0 || level.boardColumns <= 0) {
        errors.add('Level ${level.levelId}: board has invalid dimensions.');
      }
      if (level.moveLimit <= 0) {
        errors.add('Level ${level.levelId}: invalid move limit.');
      }
      if (level.goals.isEmpty) {
        warnings.add('Level ${level.levelId}: has no goals defined.');
      }
    }
    return GameDataValidationResult(warnings: warnings, errors: errors);
  }

  GameDataValidationResult validateChallenges(List<ChallengeDefinition> challenges) {
    final errors = <String>[];
    final seenIds = <String>{};
    for (final c in challenges) {
      if (!seenIds.add(c.challengeId)) {
        errors.add('Duplicate challenge ID: ${c.challengeId}');
      }
    }
    return GameDataValidationResult(errors: errors);
  }

  GameDataValidationResult validateEvents(List<EventDefinition> events) {
    final errors = <String>[];
    final seenIds = <String>{};
    for (final e in events) {
      if (!seenIds.add(e.id)) {
        errors.add('Duplicate event ID: ${e.id}');
      }
    }
    return GameDataValidationResult(errors: errors);
  }

  GameDataValidationResult validateShop(List<ShopItemDefinition> items) {
    final errors = <String>[];
    final seenIds = <String>{};
    for (final s in items) {
      if (!seenIds.add(s.id)) {
        errors.add('Duplicate shop item ID: ${s.id}');
      }
      if (s.price < 0) {
        errors.add('Shop item ${s.id} has negative price.');
      }
    }
    return GameDataValidationResult(errors: errors);
  }

  GameDataValidationResult merge(List<GameDataValidationResult> results) {
    final warnings = <String>[];
    final errors = <String>[];
    for (final r in results) {
      warnings.addAll(r.warnings);
      errors.addAll(r.errors);
    }
    return GameDataValidationResult(warnings: warnings, errors: errors);
  }
}
