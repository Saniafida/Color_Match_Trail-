import 'dart:math';
import 'daily_challenge_definition.dart';
import 'daily_challenge_type.dart';
import '../../models/level.dart';

class DailyChallengeGenerator {
  /// Generates a deterministic challenge based on the date string.
  DailyChallengeDefinition generateForDate(String dateKey) {
    // Create a simple deterministic seed from the dateKey string
    int seed = 0;
    for (int i = 0; i < dateKey.length; i++) {
      seed += dateKey.codeUnitAt(i) * (i + 1);
    }
    
    final random = Random(seed);
    
    // Pick a type
    final typeIndex = random.nextInt(DailyChallengeType.values.length);
    final type = DailyChallengeType.values[typeIndex];

    // Pick target based on type
    int target = 0;
    switch (type) {
      case DailyChallengeType.score:
        target = (random.nextInt(5) + 5) * 1000; // 5k to 10k
        break;
      case DailyChallengeType.clearBlocks:
        target = (random.nextInt(3) + 3) * 50; // 150 to 300
        break;
      case DailyChallengeType.createSpecial:
        target = random.nextInt(5) + 3; // 3 to 8
        break;
      case DailyChallengeType.cascade:
        target = random.nextInt(3) + 2; // 2 to 5 cascades
        break;
      case DailyChallengeType.combo:
        target = random.nextInt(4) + 4; // combo of 4 to 8
        break;
      case DailyChallengeType.completeLevel:
        target = 1;
        break;
    }

    // Pick reward
    final rewards = ['hammer', 'shuffle', 'rowClear', 'colorClear', 'extraMoves', 'coins'];
    final rewardId = rewards[random.nextInt(rewards.length)];
    
    int rewardAmount = 1;
    if (rewardId == 'coins') {
      rewardAmount = (random.nextInt(3) + 1) * 50; // 50, 100, 150 coins
    }

    // Pick difficulty
    final difficulties = [LevelDifficulty.easy, LevelDifficulty.medium, LevelDifficulty.hard];
    final difficulty = difficulties[random.nextInt(difficulties.length)];

    return DailyChallengeDefinition(
      id: 'daily_$dateKey',
      dateKey: dateKey,
      challengeType: type,
      target: target,
      difficulty: difficulty,
      rewardId: rewardId,
      rewardAmount: rewardAmount,
    );
  }
}
