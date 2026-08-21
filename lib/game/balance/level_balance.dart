import 'difficulty_tier.dart';

class LevelBalance {
  final String levelId;
  final DifficultyTier tier;
  final double complexityScore;
  final int estimatedMoves;
  final double estimatedClearRate;
  final int targetScore;
  final int moveLimit;
  final int colorCount;
  final List<int> starThresholds;

  const LevelBalance({
    required this.levelId,
    required this.tier,
    required this.complexityScore,
    required this.estimatedMoves,
    required this.estimatedClearRate,
    required this.targetScore,
    required this.moveLimit,
    required this.colorCount,
    required this.starThresholds,
  });

  factory LevelBalance.fromJson(Map<String, dynamic> json) {
    return LevelBalance(
      levelId: json['levelId'] as String? ?? '',
      tier: DifficultyTier.fromString(json['difficulty'] as String?),
      complexityScore: (json['complexityScore'] as num?)?.toDouble() ?? 1.0,
      estimatedMoves: json['estimatedMoves'] as int? ?? json['moveLimit'] as int? ?? 20,
      estimatedClearRate: (json['estimatedClearRate'] as num?)?.toDouble() ?? 0.8,
      targetScore: json['scoreTarget'] as int? ?? json['targetScore'] as int? ?? 1000,
      moveLimit: json['moveLimit'] as int? ?? 20,
      colorCount: json['colorCount'] as int? ?? 4,
      starThresholds: (json['starThresholds'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [1000, 2000, 3000],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'tier': tier.name,
      'complexityScore': complexityScore,
      'estimatedMoves': estimatedMoves,
      'estimatedClearRate': estimatedClearRate,
      'targetScore': targetScore,
      'moveLimit': moveLimit,
      'colorCount': colorCount,
      'starThresholds': starThresholds,
    };
  }
}
