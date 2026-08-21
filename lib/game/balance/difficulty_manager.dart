import 'difficulty_tier.dart';
import 'level_balance.dart';
import '../../models/data/level_definition.dart';

class DifficultyManager {
  const DifficultyManager();

  /// Evaluates level configuration and produces a comprehensive LevelBalance object
  LevelBalance evaluateLevel(LevelDefinitionData level) {
    final tier = DifficultyTier.fromString(level.difficulty);
    final boardCells = level.boardRows * level.boardColumns;
    final colorCount = level.blockTypes.isNotEmpty ? 4 : 4; // default base colors

    // Calculate goals complexity
    double goalsWeight = 0;
    for (final goal in level.goals) {
      goalsWeight += (goal.targetAmount * 0.1);
    }
    if (goalsWeight == 0) goalsWeight = 1.0;

    // Complexity score formula based on board dimensions, colors, move constraints, and goals
    final complexityScore = ((boardCells / 36.0) * (colorCount / 4.0) * goalsWeight / (level.moveLimit > 0 ? (level.moveLimit / 20.0) : 1.0)) * tier.complexityWeight;

    // Estimate realistic moves to complete
    final estimatedMoves = (goalsWeight * (colorCount * 0.8) + (level.boardRows * 0.5)).round().clamp(10, 50);

    // Estimate clear rate based on tier
    double estimatedClearRate = 0.85;
    switch (tier) {
      case DifficultyTier.easy:
        estimatedClearRate = 0.95;
        break;
      case DifficultyTier.normal:
        estimatedClearRate = 0.80;
        break;
      case DifficultyTier.hard:
        estimatedClearRate = 0.60;
        break;
      case DifficultyTier.expert:
        estimatedClearRate = 0.40;
        break;
    }

    return LevelBalance(
      levelId: level.levelId,
      tier: tier,
      complexityScore: double.parse(complexityScore.toStringAsFixed(2)),
      estimatedMoves: estimatedMoves,
      estimatedClearRate: estimatedClearRate,
      targetScore: level.scoreTarget,
      moveLimit: level.moveLimit,
      colorCount: colorCount,
      starThresholds: level.starThresholds,
    );
  }

  /// Checks for sudden difficulty spikes across adjacent levels in a campaign sequence.
  /// Returns a list of warning strings if spikes exist.
  List<String> detectDifficultySpikes(List<LevelDefinitionData> orderedLevels) {
    final List<String> warnings = [];
    if (orderedLevels.length < 2) return warnings;

    for (int i = 0; i < orderedLevels.length - 1; i++) {
      final current = evaluateLevel(orderedLevels[i]);
      final next = evaluateLevel(orderedLevels[i + 1]);

      final tierDiff = next.tier.index - current.tier.index;
      if (tierDiff > 1) {
        warnings.add(
          'Difficulty spike detected between Level ${current.levelId} (${current.tier.displayName}) and Level ${next.levelId} (${next.tier.displayName}).',
        );
      }
    }

    return warnings;
  }
}
