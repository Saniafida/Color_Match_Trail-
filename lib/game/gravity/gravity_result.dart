import '../../models/models.dart';

class GravityMove {
  final String blockId;
  final Position fromPosition;
  final Position toPosition;
  final int distance;

  const GravityMove({
    required this.blockId,
    required this.fromPosition,
    required this.toPosition,
    required this.distance,
  });
}

class SpawnedBlock {
  final String blockId;
  final BlockColor color;
  final Position destinationPosition;
  final int spawnIndex;

  const SpawnedBlock({
    required this.blockId,
    required this.color,
    required this.destinationPosition,
    required this.spawnIndex,
  });
}

class GravityResult {
  final List<GravityMove> movedBlocks;
  final List<SpawnedBlock> spawnedBlocks;
  final int emptyCellsBefore;
  final int emptyCellsAfter;
  final bool hasMovedBlocks;
  final bool hasSpawnedBlocks;
  final bool cascadeCheckRequired;

  const GravityResult({
    this.movedBlocks = const [],
    this.spawnedBlocks = const [],
    this.emptyCellsBefore = 0,
    this.emptyCellsAfter = 0,
    this.hasMovedBlocks = false,
    this.hasSpawnedBlocks = false,
    this.cascadeCheckRequired = false,
  });
}
