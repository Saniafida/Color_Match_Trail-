import 'progression_state.dart';
import '../../core/data/game_data_manager.dart';
import '../../models/world_definition.dart';

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
    WorldDefinition? world;
    for (final w in allWorlds) {
      if (w.levelIds.contains(levelId)) {
        world = w;
        break;
      }
    }

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

    // 4. Level 1 is always unlocked
    final currentLevelNum = int.tryParse(levelId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (currentLevelNum == 1) {
      return LevelUnlockValidationResult.unlocked();
    }

    // 5. If previous level is completed, it is unlocked
    if (currentLevelNum != null && currentLevelNum > 1) {
      final prevLevelId = 'level_${currentLevelNum - 1}';
      final prevProgress = state.levels[prevLevelId];
      if (prevProgress != null && prevProgress.completed) {
        return LevelUnlockValidationResult.unlocked();
      }
      return LevelUnlockValidationResult.locked(
        status: LevelUnlockStatus.lockedPreviousLevel,
        message: 'Complete level ${currentLevelNum - 1} to unlock.',
        requiredLevelId: prevLevelId,
      );
    }

    return LevelUnlockValidationResult.locked(
      status: LevelUnlockStatus.lockedPreviousLevel,
      message: 'Level is locked.',
    );
  }
}
