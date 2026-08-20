import 'daily_challenge_type.dart';
import '../../models/level.dart'; // For LevelDifficulty

class DailyChallengeDefinition {
  final String id;
  final String dateKey; // e.g., '2026-08-20'
  final DailyChallengeType challengeType;
  final int target;
  final LevelDifficulty difficulty;
  
  // What the user gets
  final String rewardId; // e.g. "coins", "hammer", etc.
  final int rewardAmount;

  const DailyChallengeDefinition({
    required this.id,
    required this.dateKey,
    required this.challengeType,
    required this.target,
    required this.difficulty,
    required this.rewardId,
    required this.rewardAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateKey': dateKey,
      'challengeType': challengeType.name,
      'target': target,
      'difficulty': difficulty.name,
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
        orElse: () => DailyChallengeType.score,
      ),
      target: json['target'] as int,
      difficulty: LevelDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => LevelDifficulty.medium,
      ),
      rewardId: json['rewardId'] as String,
      rewardAmount: json['rewardAmount'] as int,
    );
  }
}
