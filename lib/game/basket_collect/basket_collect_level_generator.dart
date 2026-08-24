import 'dart:math';
import '../../models/models.dart';
import 'basket_collect_level_model.dart';

class BasketCollectLevelGenerator {
  static final Random _rng = Random();

  static BasketCollectLevel getLevel(int levelNumber) {
    switch (levelNumber) {
      case 1:
        // Level 1: Very Easy
        return const BasketCollectLevel(
          levelNumber: 1,
          moves: 20,
          goalTotal: 10,
          fallSpeedMultiplier: 0.8,
          spawnIntervalMs: 1400,
          activeColors: [BlockColor.red, BlockColor.yellow],
          targetRequirements: {
            BlockColor.red: 10,
          },
        );

      case 2:
        return const BasketCollectLevel(
          levelNumber: 2,
          moves: 20,
          goalTotal: 15,
          fallSpeedMultiplier: 0.85,
          spawnIntervalMs: 1300,
          activeColors: [BlockColor.red, BlockColor.yellow],
          targetRequirements: {
            BlockColor.red: 8,
            BlockColor.yellow: 7,
          },
        );

      case 3:
        return const BasketCollectLevel(
          levelNumber: 3,
          moves: 22,
          goalTotal: 25,
          fallSpeedMultiplier: 0.95,
          spawnIntervalMs: 1150,
          activeColors: [BlockColor.red, BlockColor.yellow, BlockColor.blue],
          targetRequirements: {
            BlockColor.red: 10,
            BlockColor.yellow: 8,
            BlockColor.blue: 7,
          },
        );

      case 4:
      case 5:
        // Level 5 (Exact Reference Screenshot Layout: Goal 60, Moves 25)
        return const BasketCollectLevel(
          levelNumber: 5,
          moves: 25,
          goalTotal: 60,
          fallSpeedMultiplier: 1.05,
          spawnIntervalMs: 950,
          activeColors: [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.green,
            BlockColor.purple,
          ],
          targetRequirements: {
            BlockColor.red: 15,
            BlockColor.yellow: 15,
            BlockColor.blue: 15,
            BlockColor.green: 15,
          },
          hasPowerBlocks: true,
        );

      default:
        // Procedural generator
        final colorCount = (levelNumber < 8) ? 3 : ((levelNumber < 15) ? 4 : 5);
        final colors = [
          BlockColor.red,
          BlockColor.yellow,
          BlockColor.blue,
          BlockColor.green,
          BlockColor.purple,
        ].sublist(0, colorCount);

        final goalTotal = min(30 + (levelNumber * 5), 100);
        final moves = min(20 + (levelNumber ~/ 3), 40);
        final speed = min(0.9 + (levelNumber * 0.05), 2.2);
        final interval = max(1200 - (levelNumber * 40), 450);

        final Map<BlockColor, int> targets = {};
        final perColor = goalTotal ~/ colorCount;
        for (final c in colors) {
          targets[c] = perColor;
        }

        return BasketCollectLevel(
          levelNumber: levelNumber,
          moves: moves,
          goalTotal: goalTotal,
          fallSpeedMultiplier: speed,
          spawnIntervalMs: interval,
          activeColors: colors,
          targetRequirements: targets,
          hasPowerBlocks: levelNumber >= 5,
        );
    }
  }

  static BlockColor getRandomColor(BasketCollectLevel level) {
    return level.activeColors[_rng.nextInt(level.activeColors.length)];
  }
}
