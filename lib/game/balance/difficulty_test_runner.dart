import '../../models/data/level_definition.dart';
import '../levels/level_playability_validator.dart';
import 'difficulty_manager.dart';

class LevelSimulationResult {
  final String levelId;
  final bool isPlayable;
  final double complexityScore;
  final int estimatedMoves;
  final double estimatedClearRate;
  final double deadBoardFrequency;

  const LevelSimulationResult({
    required this.levelId,
    required this.isPlayable,
    required this.complexityScore,
    required this.estimatedMoves,
    required this.estimatedClearRate,
    this.deadBoardFrequency = 0.0,
  });
}

class DifficultyTestRunner {
  final DifficultyManager difficultyManager = const DifficultyManager();
  final LevelPlayabilityValidator playabilityValidator = const LevelPlayabilityValidator();

  const DifficultyTestRunner();

  /// Runs offline simulation on a single level definition
  LevelSimulationResult evaluate(LevelDefinitionData level, {int simulationRuns = 5}) {
    final balance = difficultyManager.evaluateLevel(level);
    
    int playableRuns = 0;
    for (int i = 0; i < simulationRuns; i++) {
      final playability = playabilityValidator.validatePlayability(level, seed: 1000 + i);
      if (playability.isPlayable) {
        playableRuns++;
      }
    }

    final deadBoardFrequency = 1.0 - (playableRuns / simulationRuns);

    return LevelSimulationResult(
      levelId: level.levelId,
      isPlayable: playableRuns > 0,
      complexityScore: balance.complexityScore,
      estimatedMoves: balance.estimatedMoves,
      estimatedClearRate: balance.estimatedClearRate,
      deadBoardFrequency: deadBoardFrequency,
    );
  }

  /// Runs offline simulation over the entire campaign
  List<LevelSimulationResult> evaluateCampaign(List<LevelDefinitionData> levels) {
    return levels.map((lvl) => evaluate(lvl)).toList();
  }
}
