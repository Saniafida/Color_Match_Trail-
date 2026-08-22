import 'dart:math';
import 'daily_challenge_definition.dart';
import 'daily_challenge_type.dart';
import '../../models/level.dart';
import '../../models/block.dart';

class DailyChallengeGenerator {
  /// Generates a deterministic 2-color challenge based on the date string.
  DailyChallengeDefinition generateForDate(String dateKey) {
    int seed = 0;
    for (int i = 0; i < dateKey.length; i++) {
      seed += dateKey.codeUnitAt(i) * (i + 1);
    }
    
    final random = Random(seed);
    
    // Pick 2 distinct colors
    final colors = List<BlockColor>.from(BlockColor.values);
    colors.shuffle(random);
    final color1 = colors[0];
    final color2 = colors[1];

    // Pick realistic, fun targets for each color (e.g. 20 to 35 blocks)
    final target1 = (random.nextInt(4) + 4) * 5; // 20, 25, 30, 35
    final target2 = (random.nextInt(4) + 4) * 5; // 20, 25, 30, 35

    // Rewards
    final rewards = ['coins', 'hammer', 'shuffle', 'rowClear', 'coins'];
    final rewardId = rewards[random.nextInt(rewards.length)];
    
    int rewardAmount = 1;
    if (rewardId == 'coins') {
      rewardAmount = (random.nextInt(3) + 2) * 50; // 100, 150, 200 coins
    }

    final difficulties = [LevelDifficulty.easy, LevelDifficulty.medium, LevelDifficulty.hard];
    final difficulty = difficulties[random.nextInt(difficulties.length)];

    return DailyChallengeDefinition(
      id: 'daily_$dateKey',
      dateKey: dateKey,
      challengeType: DailyChallengeType.twoColors,
      target: target1 + target2,
      primaryColor: color1,
      secondaryColor: color2,
      primaryTarget: target1,
      secondaryTarget: target2,
      difficulty: difficulty,
      rewardId: rewardId,
      rewardAmount: rewardAmount,
    );
  }
}

