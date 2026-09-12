import 'dart:math';
import 'daily_challenge_definition.dart';
import 'daily_challenge_type.dart';
import '../../models/level.dart';
import '../../models/block.dart';

class DailyChallengeGenerator {
  static const List<int> dayCoinRewards = [100, 150, 200, 250, 300, 350, 500];

  /// Generates a deterministic 2-color challenge based on the date string and day index.
  DailyChallengeDefinition generateForDate(String dateKey, [int day = 1]) {
    final clampedDay = day.clamp(1, 7);
    int seed = 0;
    for (int i = 0; i < dateKey.length; i++) {
      seed += dateKey.codeUnitAt(i) * (i + 1);
    }
    seed += clampedDay * 17;
    
    final random = Random(seed);
    
    // Pick 2 distinct colors
    final colors = List<BlockColor>.from(BlockColor.values);
    colors.shuffle(random);
    final color1 = colors[0];
    final color2 = colors[1];

    // Pick realistic, fun targets for each color (e.g. 20 to 35 blocks)
    final target1 = (random.nextInt(4) + 4) * 5; // 20, 25, 30, 35
    final target2 = (random.nextInt(4) + 4) * 5; // 20, 25, 30, 35

    // Escalating 7-day coins rewards matching Day 1 (100) through Day 7 (500)
    final rewardAmount = dayCoinRewards[clampedDay - 1];
    final rewardId = 'coins';

    final difficulties = [LevelDifficulty.easy, LevelDifficulty.medium, LevelDifficulty.hard];
    final difficulty = difficulties[random.nextInt(difficulties.length)];

    return DailyChallengeDefinition(
      id: 'daily_${dateKey}_day$clampedDay',
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
