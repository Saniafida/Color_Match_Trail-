import 'progression_state.dart';
import '../../core/data/game_data_manager.dart';

enum WorldUnlockStatus {
  unlocked,
  lockedStars,
  lockedPreviousWorld,
  worldNotFound,
  worldDisabled,
}

class WorldUnlockValidationResult {
  final bool isUnlocked;
  final WorldUnlockStatus status;
  final String? message;
  final int requiredStars;
  final int currentStars;
  final String? requiredWorldId;

  const WorldUnlockValidationResult({
    required this.isUnlocked,
    required this.status,
    this.message,
    this.requiredStars = 0,
    this.currentStars = 0,
    this.requiredWorldId,
  });

  factory WorldUnlockValidationResult.unlocked() {
    return const WorldUnlockValidationResult(
      isUnlocked: true,
      status: WorldUnlockStatus.unlocked,
    );
  }

  factory WorldUnlockValidationResult.locked({
    required WorldUnlockStatus status,
    String? message,
    int requiredStars = 0,
    int currentStars = 0,
    String? requiredWorldId,
  }) {
    return WorldUnlockValidationResult(
      isUnlocked: false,
      status: status,
      message: message,
      requiredStars: requiredStars,
      currentStars: currentStars,
      requiredWorldId: requiredWorldId,
    );
  }
}

class WorldUnlockValidator {
  static WorldUnlockValidationResult validate({
    required String worldId,
    required ProgressionState state,
    required GameDataManager dataManager,
  }) {
    final world = dataManager.getWorld(worldId);
    if (world == null) {
      return WorldUnlockValidationResult.locked(
        status: WorldUnlockStatus.worldNotFound,
        message: 'World $worldId not found.',
      );
    }

    if (!world.enabled) {
      return WorldUnlockValidationResult.locked(
        status: WorldUnlockStatus.worldDisabled,
        message: 'World is currently disabled.',
      );
    }

    // First world is always unlocked
    final allWorlds = dataManager.getAllWorlds();
    if (allWorlds.isNotEmpty && allWorlds.first.worldId == worldId) {
      return WorldUnlockValidationResult.unlocked();
    }

    // Check if recorded as unlocked
    if (state.unlockedWorlds.contains(worldId)) {
      return WorldUnlockValidationResult.unlocked();
    }

    // Calculate total stars
    int totalStars = 0;
    for (final lp in state.levels.values) {
      totalStars += lp.stars;
    }

    // Check star requirement
    if (totalStars < world.unlockRequirement) {
      return WorldUnlockValidationResult.locked(
        status: WorldUnlockStatus.lockedStars,
        message: 'Requires ${world.unlockRequirement} stars (have $totalStars)',
        requiredStars: world.unlockRequirement,
        currentStars: totalStars,
      );
    }

    // Check previous world completed
    final worldIndex = allWorlds.indexWhere((w) => w.worldId == worldId);
    if (worldIndex > 0) {
      final prevWorld = allWorlds[worldIndex - 1];
      final allPrevCompleted = prevWorld.levelIds.every((lvlId) {
        return state.levels[lvlId]?.completed ?? false;
      });

      if (!allPrevCompleted) {
        return WorldUnlockValidationResult.locked(
          status: WorldUnlockStatus.lockedPreviousWorld,
          message: 'Complete all levels in previous world to unlock.',
          requiredWorldId: prevWorld.worldId,
          requiredStars: world.unlockRequirement,
          currentStars: totalStars,
        );
      }
    }

    return WorldUnlockValidationResult.unlocked();
  }
}
