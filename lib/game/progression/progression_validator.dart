import 'progression_state.dart';
import 'level_progress.dart';
import '../../core/data/game_data_manager.dart';

class ProgressionValidator {
  static ProgressionState validateAndRepair(ProgressionState state, GameDataManager dataManager) {
    final levels = Map<String, LevelProgress>.from(state.levels);
    final unlockedWorlds = Set<String>.from(state.unlockedWorlds);
    String? currentLevel = state.currentLevel;

    // Ensure First Level is Unlocked
    final allWorlds = dataManager.getAllWorlds();
    if (allWorlds.isNotEmpty) {
      final firstWorld = allWorlds.first;
      unlockedWorlds.add(firstWorld.worldId);
      
      if (firstWorld.levelIds.isNotEmpty) {
        final firstLevelId = firstWorld.levelIds.first;
        if (levels[firstLevelId] == null) {
          levels[firstLevelId] = LevelProgress.unlocked(firstLevelId);
        } else if (!levels[firstLevelId]!.unlocked) {
          levels[firstLevelId] = levels[firstLevelId]!.copyWith(unlocked: true);
        }
      }
    }

    // Repair Impossible States: If level N is unlocked, ensure N-1 is completed (unless N is first level in world)
    for (final world in allWorlds) {
      bool previousCompleted = true;
      for (int i = 0; i < world.levelIds.length; i++) {
        final levelId = world.levelIds[i];
        final progress = levels[levelId];
        
        if (progress != null && progress.unlocked) {
          if (!previousCompleted && i > 0) {
            // Repair: lock it if the previous isn't completed
            levels[levelId] = progress.copyWith(unlocked: false);
          }
        }
        previousCompleted = levels[levelId]?.completed ?? false;
      }
    }

    return state.copyWith(
      levels: levels,
      unlockedWorlds: unlockedWorlds,
      currentLevel: currentLevel,
    );
  }
}
