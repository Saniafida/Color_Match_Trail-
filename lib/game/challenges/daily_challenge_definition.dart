import 'daily_challenge_type.dart';
import '../../models/level.dart'; // For LevelDifficulty
import '../../models/block.dart'; // For BlockColor

class DailyChallengeDefinition {
  final String id;
  final String dateKey; // e.g., '2026-08-20'
  final DailyChallengeType challengeType;
  final int target;
  final LevelDifficulty difficulty;
  
  // 2-Color block targets
  final BlockColor primaryColor;
  final BlockColor secondaryColor;
  final int primaryTarget;
  final int secondaryTarget;

  // What the user gets
  final String rewardId; // e.g. "coins", "hammer", etc.
  final int rewardAmount;

  const DailyChallengeDefinition({
    required this.id,
    required this.dateKey,
    required this.challengeType,
    required this.target,
    required this.difficulty,
    this.primaryColor = BlockColor.red,
    this.secondaryColor = BlockColor.green,
    int? primaryTarget,
    int? secondaryTarget,
    required this.rewardId,
    required this.rewardAmount,
  })  : primaryTarget = primaryTarget ?? target,
        secondaryTarget = secondaryTarget ?? target;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateKey': dateKey,
      'challengeType': challengeType.name,
      'target': target,
      'difficulty': difficulty.name,
      'primaryColor': primaryColor.name,
      'secondaryColor': secondaryColor.name,
      'primaryTarget': primaryTarget,
      'secondaryTarget': secondaryTarget,
      'rewardId': rewardId,
      'rewardAmount': rewardAmount,
    };
  }

  factory DailyChallengeDefinition.fromJson(Map<String, dynamic> json) {
    return DailyChallengeDefinition(
      id: json['id'] as String,
      dateKey: json['dateKey'] as String,
      challengeType: DailyChallengeType.values.firstWhere(
        (e) => e.name == json['challengeType'],
        orElse: () => DailyChallengeType.twoColors,
      ),
      target: json['target'] as int? ?? 30,
      difficulty: LevelDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => LevelDifficulty.medium,
      ),
      primaryColor: json['primaryColor'] != null
          ? BlockColor.values.firstWhere(
              (e) => e.name == json['primaryColor'],
              orElse: () => BlockColor.red,
            )
          : BlockColor.red,
      secondaryColor: json['secondaryColor'] != null
          ? BlockColor.values.firstWhere(
              (e) => e.name == json['secondaryColor'],
              orElse: () => BlockColor.green,
            )
          : BlockColor.green,
      primaryTarget: json['primaryTarget'] as int? ?? json['target'] as int? ?? 30,
      secondaryTarget: json['secondaryTarget'] as int? ?? json['target'] as int? ?? 30,
      rewardId: json['rewardId'] as String? ?? 'coins',
      rewardAmount: json['rewardAmount'] as int? ?? 100,
    );
  }
}

