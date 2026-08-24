import '../../models/models.dart';

class BasketCollectLevel {
  final int levelNumber;
  final int moves;
  final int goalTotal;
  final Map<BlockColor, int> targetRequirements;
  final List<BlockColor> activeColors;
  final double fallSpeedMultiplier;
  final int spawnIntervalMs;
  final bool hasPowerBlocks;

  const BasketCollectLevel({
    required this.levelNumber,
    required this.moves,
    required this.goalTotal,
    required this.targetRequirements,
    required this.activeColors,
    this.fallSpeedMultiplier = 1.0,
    this.spawnIntervalMs = 1100,
    this.hasPowerBlocks = false,
  });
}
