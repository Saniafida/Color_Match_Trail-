import 'dart:math';
import '../../models/models.dart';
import 'basket_collect_level_model.dart';

class BasketCollectLevelGenerator {
  static final Random _rng = Random();

  static BasketCollectLevel getLevel(int levelNumber) {
    switch (levelNumber) {
      // ══════════════════════════════════════════════
      // LEVEL 1 — Tutorial / Very Easy
      // Goal: Catch 5 red hearts. 15 moves. 5 lives.
      // ══════════════════════════════════════════════
      case 1:
        return const BasketCollectLevel(
          levelNumber: 1,
          moves: 15,
          goalTotal: 5,
          fallSpeedMultiplier: 0.65,
          spawnIntervalMs: 700,
          activeColors: BlockColor.values,
          targetRequirements: {
            BlockColor.red: 5,
          },
          maxMisses: 5,
          basketWidthFactor: 1.20,
        );

      // ══════════════════════════════════════════════
      // LEVEL 2 — Very Easy
      // ══════════════════════════════════════════════
      case 2:
        return const BasketCollectLevel(
          levelNumber: 2,
          moves: 18,
          goalTotal: 8,
          fallSpeedMultiplier: 0.70,
          spawnIntervalMs: 650,
          activeColors: BlockColor.values,
          targetRequirements: {
            BlockColor.red: 5,
            BlockColor.yellow: 3,
          },
          maxMisses: 5,
          basketWidthFactor: 1.15,
        );

      // ══════════════════════════════════════════════
      // LEVEL 3 — Easy
      // ══════════════════════════════════════════════
      case 3:
        return const BasketCollectLevel(
          levelNumber: 3,
          moves: 22,
          goalTotal: 12,
          fallSpeedMultiplier: 0.80,
          spawnIntervalMs: 600,
          activeColors: BlockColor.values,
          targetRequirements: {
            BlockColor.red: 5,
            BlockColor.yellow: 4,
            BlockColor.blue: 3,
          },
          maxMisses: 5,
          basketWidthFactor: 1.10,
        );

      // ══════════════════════════════════════════════
      // LEVEL 4 — Easy
      // ══════════════════════════════════════════════
      case 4:
        return const BasketCollectLevel(
          levelNumber: 4,
          moves: 25,
          goalTotal: 15,
          fallSpeedMultiplier: 0.90,
          spawnIntervalMs: 550,
          activeColors: BlockColor.values,
          targetRequirements: {
            BlockColor.red: 6,
            BlockColor.yellow: 5,
            BlockColor.blue: 4,
          },
          maxMisses: 5,
          basketWidthFactor: 1.05,
        );

      // ══════════════════════════════════════════════
      // LEVEL 5 — Easy-Medium
      // ══════════════════════════════════════════════
      case 5:
        return const BasketCollectLevel(
          levelNumber: 5,
          moves: 30,
          goalTotal: 20,
          fallSpeedMultiplier: 1.0,
          spawnIntervalMs: 500,
          activeColors: BlockColor.values,
          targetRequirements: {
            BlockColor.red: 6,
            BlockColor.yellow: 5,
            BlockColor.blue: 5,
            BlockColor.green: 4,
          },
          maxMisses: 5,
          basketWidthFactor: 1.0,
          hasPowerBlocks: true,
        );

      default:
        // ══════════════════════════════════════════
        // PROCEDURAL GENERATOR FOR LEVELS 6+
        // ══════════════════════════════════════════
        final colorCount = min(3 + (levelNumber ~/ 4), 6);
        final targetColors = BlockColor.values.sublist(0, colorCount);

        final goalTotal = min(15 + (levelNumber * 3), 80);
        final moves = min(25 + (levelNumber ~/ 2), 50);
        final speed = min(0.95 + (levelNumber * 0.045), 2.0);
        final interval = max(600 - (levelNumber * 20), 380);
        final misses = 5;

        final Map<BlockColor, int> targets = {};
        final perColor = goalTotal ~/ colorCount;
        for (final c in targetColors) {
          targets[c] = perColor;
        }

        return BasketCollectLevel(
          levelNumber: levelNumber,
          moves: moves,
          goalTotal: goalTotal,
          fallSpeedMultiplier: speed,
          spawnIntervalMs: interval,
          activeColors: BlockColor.values,
          targetRequirements: targets,
          maxMisses: misses,
          hasPowerBlocks: levelNumber >= 5,
        );
    }
  }

  /// Returns random color with all rainbow colors falling and target bias for playability.
  static BlockColor getRandomColor(BasketCollectLevel level) {
    final targetColors = level.targetRequirements.keys.toList();
    final allColors = BlockColor.values;

    // 40% bias toward target requirements, 60% random across all rainbow colors
    if (_rng.nextDouble() < 0.40 && targetColors.isNotEmpty) {
      return targetColors[_rng.nextInt(targetColors.length)];
    }
    return allColors[_rng.nextInt(allColors.length)];
  }
}
