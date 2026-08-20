import 'score_config.dart';
import 'score_breakdown.dart';
import '../combo/combo_config.dart';

class ScoreCalculator {
  static ScoreBreakdown calculate({
    required int destroyedBlocks,
    required int cascadeLevel,
    required int comboLevel,
  }) {
    final baseScore = destroyedBlocks * ScoreConfig.baseScorePerBlock;
    final connMult = ScoreConfig.getConnectionMultiplier(destroyedBlocks);
    final casMult = ScoreConfig.getCascadeMultiplier(cascadeLevel);
    final comboMult = ComboConfig.getMultiplier(comboLevel);

    final finalScore = (baseScore * connMult * casMult * comboMult).round();

    return ScoreBreakdown(
      destroyedBlocks: destroyedBlocks,
      baseScore: baseScore,
      connectionMultiplier: connMult,
      cascadeMultiplier: casMult,
      comboMultiplier: comboMult,
      finalScore: finalScore,
      cascadeLevel: cascadeLevel,
      comboLevel: comboLevel,
    );
  }
}
