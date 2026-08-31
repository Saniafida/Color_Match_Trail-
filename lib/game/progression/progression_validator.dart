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

    // Repair Impossible States: If level N is unlocked, ensure N-1 is completed
    for (int lvl = 1; lvl <= 147; lvl++) {
      final levelId = 'level_$lvl';
      final progress = levels[levelId];
      if (lvl > 1 && progress != null && progress.unlocked) {
        final prevProgress = levels['level_${lvl - 1}'];
        if (prevProgress == null || !prevProgress.completed) {
          levels[levelId] = progress.copyWith(unlocked: false);
        }
      }
      if (progress != null && (progress.unlocked || progress.completed)) {
        for (final world in allWorlds) {
          if (world.levelIds.contains(levelId)) {
            unlockedWorlds.add(world.worldId);
            break;
          }
        }
      }
    }

    return state.copyWith(
      levels: levels,
      unlockedWorlds: unlockedWorlds,
      currentLevel: currentLevel ?? 'level_1',
    );
  }
}
