import 'progression_state.dart';
import '../../core/data/game_data_manager.dart';

enum LevelUnlockStatus {
  unlocked,
  lockedPreviousLevel,
  lockedStars,
  lockedWorld,
  levelNotFound,
  levelDisabled,
}

class LevelUnlockValidationResult {
  final bool isUnlocked;
  final LevelUnlockStatus status;
  final String? message;
  final int requiredStars;
  final String? requiredLevelId;

  const LevelUnlockValidationResult({
    required this.isUnlocked,
    required this.status,
    this.message,
    this.requiredStars = 0,
    this.requiredLevelId,
  });

  factory LevelUnlockValidationResult.unlocked() {
    return const LevelUnlockValidationResult(
      isUnlocked: true,
      status: LevelUnlockStatus.unlocked,
    );
  }

  factory LevelUnlockValidationResult.locked({
    required LevelUnlockStatus status,
    String? message,
    int requiredStars = 0,
    String? requiredLevelId,
  }) {
    return LevelUnlockValidationResult(
      isUnlocked: false,
      status: status,
      message: message,
      requiredStars: requiredStars,
      requiredLevelId: requiredLevelId,
    );
  }
}

class LevelUnlockValidator {
  static LevelUnlockValidationResult validate({
    required String levelId,
    required ProgressionState state,
    required GameDataManager dataManager,
  }) {
    // 1. Check if level data exists
    final levelData = dataManager.getLevel(levelId);
    if (levelData == null) {
      return LevelUnlockValidationResult.locked(
        status: LevelUnlockStatus.levelNotFound,
        message: 'Level $levelId not found.',
      );
    }

    // 2. Find which world contains this level
    final allWorlds = dataManager.getAllWorlds();
    final world = allWorlds.firstWhere(
      (w) => w.levelIds.contains(levelId),
      orElse: () => allWorlds.isNotEmpty ? allWorlds.first : null as dynamic,
    );

    if (world != null) {
      if (!world.enabled) {
        return LevelUnlockValidationResult.locked(
          status: LevelUnlockStatus.levelDisabled,
          message: 'World ${world.worldId} is currently disabled.',
        );
      }

      // Check if world is unlocked
      if (!state.unlockedWorlds.contains(world.worldId)) {
        return LevelUnlockValidationResult.locked(
          status: LevelUnlockStatus.lockedWorld,
          message: 'World ${world.worldId} is locked.',
          requiredStars: world.unlockRequirement,
        );
      }
    }

    // 3. Check level progress state
    final progress = state.levels[levelId];
    if (progress != null && progress.unlocked) {
      return LevelUnlockValidationResult.unlocked();
    }

    // 4. If not explicitly recorded as unlocked, check if it's the first level of the first world
    if (world != null && world.levelIds.isNotEmpty && world.levelIds.first == levelId) {
      if (allWorlds.isNotEmpty && allWorlds.first.worldId == world.worldId) {
        return LevelUnlockValidationResult.unlocked();
      }
    }

    // 5. Determine prerequisite level if any
    String? previousLevelId;
    if (world != null) {
      final index = world.levelIds.indexOf(levelId);
      if (index > 0) {
        previousLevelId = world.levelIds[index - 1];
        final prevProgress = state.levels[previousLevelId];
        if (prevProgress == null || !prevProgress.completed) {
          return LevelUnlockValidationResult.locked(
            status: LevelUnlockStatus.lockedPreviousLevel,
            message: 'Complete level ${previousLevelId.replaceAll(RegExp(r'[^0-9]'), '')} to unlock.',
            requiredLevelId: previousLevelId,
          );
        }
      }
    }

    return LevelUnlockValidationResult.locked(
      status: LevelUnlockStatus.lockedPreviousLevel,
      message: 'Level is locked.',
      requiredLevelId: previousLevelId,
    );
  }
}
