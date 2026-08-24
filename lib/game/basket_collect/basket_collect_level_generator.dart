import 'dart:math';
import '../../models/models.dart';
import 'basket_collect_level_model.dart';

class BasketCollectLevelGenerator {
  static final Random _rng = Random();

  static BasketCollectLevel getLevel(int levelNumber) {
    switch (levelNumber) {
      // ══════════════════════════════════════════════
      // LEVEL 1 — Tutorial / Very Easy
      // Goal: Catch 5 red hearts. 10 moves. 3 lives.
      // Very slow blocks. Wide basket.
      // ══════════════════════════════════════════════
      case 1:
        return const BasketCollectLevel(
          levelNumber: 1,
          moves: 10,
          goalTotal: 5,
          fallSpeedMultiplier: 0.55,
          spawnIntervalMs: 1900,
          activeColors: [BlockColor.red, BlockColor.yellow],
          targetRequirements: {
            BlockColor.red: 5,
          },
          maxMisses: 3,
          basketWidthFactor: 1.25,
        );

      // ══════════════════════════════════════════════
      // LEVEL 2 — Very Easy
      // ══════════════════════════════════════════════
      case 2:
        return const BasketCollectLevel(
          levelNumber: 2,
          moves: 14,
          goalTotal: 8,
          fallSpeedMultiplier: 0.65,
          spawnIntervalMs: 1600,
          activeColors: [BlockColor.red, BlockColor.yellow],
          targetRequirements: {
            BlockColor.red: 5,
            BlockColor.yellow: 3,
          },
          maxMisses: 3,
          basketWidthFactor: 1.15,
        );

      // ══════════════════════════════════════════════
      // LEVEL 3 — Easy
      // ══════════════════════════════════════════════
      case 3:
        return const BasketCollectLevel(
          levelNumber: 3,
          moves: 18,
          goalTotal: 12,
          fallSpeedMultiplier: 0.75,
          spawnIntervalMs: 1400,
          activeColors: [BlockColor.red, BlockColor.yellow, BlockColor.blue],
          targetRequirements: {
            BlockColor.red: 5,
            BlockColor.yellow: 4,
            BlockColor.blue: 3,
          },
          maxMisses: 3,
          basketWidthFactor: 1.1,
        );

      // ══════════════════════════════════════════════
      // LEVEL 4 — Easy
      // ══════════════════════════════════════════════
      case 4:
        return const BasketCollectLevel(
          levelNumber: 4,
          moves: 20,
          goalTotal: 15,
          fallSpeedMultiplier: 0.85,
          spawnIntervalMs: 1250,
          activeColors: [BlockColor.red, BlockColor.yellow, BlockColor.blue],
          targetRequirements: {
            BlockColor.red: 6,
            BlockColor.yellow: 5,
            BlockColor.blue: 4,
          },
          maxMisses: 3,
          basketWidthFactor: 1.05,
        );

      // ══════════════════════════════════════════════
      // LEVEL 5 — Easy-Medium
      // ══════════════════════════════════════════════
      case 5:
        return const BasketCollectLevel(
          levelNumber: 5,
          moves: 25,
          goalTotal: 20,
          fallSpeedMultiplier: 1.0,
          spawnIntervalMs: 1100,
          activeColors: [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.green,
          ],
          targetRequirements: {
            BlockColor.red: 6,
            BlockColor.yellow: 5,
            BlockColor.blue: 5,
            BlockColor.green: 4,
          },
          maxMisses: 3,
          basketWidthFactor: 1.0,
          hasPowerBlocks: true,
        );

      default:
        // ══════════════════════════════════════════
        // PROCEDURAL GENERATOR FOR LEVELS 6+
        // ══════════════════════════════════════════
        final colorCount = levelNumber < 8
            ? 3
            : (levelNumber < 15 ? 4 : 5);
        final colors = [
          BlockColor.red,
          BlockColor.yellow,
          BlockColor.blue,
          BlockColor.green,
          BlockColor.purple,
        ].sublist(0, colorCount);

        final goalTotal = min(15 + (levelNumber * 3), 80);
        final moves = min(20 + (levelNumber ~/ 2), 40);
        final speed = min(0.95 + (levelNumber * 0.045), 2.2);
        final interval = max(1100 - (levelNumber * 35), 400);
        // Lives decrease as level gets harder (min 2)
        final misses = levelNumber < 15 ? 3 : (levelNumber < 25 ? 3 : 2);

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
          maxMisses: misses,
          hasPowerBlocks: levelNumber >= 5,
        );
    }
  }

  /// Returns a weighted-random color — heavily biases toward target colors.
  static BlockColor getRandomColor(BasketCollectLevel level) {
    // 75% chance to spawn a target color, 25% non-target (if any non-target exists)
    final targetColors = level.targetRequirements.keys.toList();
    final allColors = level.activeColors;
    final nonTargetColors =
        allColors.where((c) => !targetColors.contains(c)).toList();

    final roll = _rng.nextDouble();
    if (nonTargetColors.isNotEmpty && roll > 0.75) {
      return nonTargetColors[_rng.nextInt(nonTargetColors.length)];
    }
    return targetColors[_rng.nextInt(targetColors.length)];
  }
}
