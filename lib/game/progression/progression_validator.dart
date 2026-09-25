import 'progression_state.dart';
import 'level_progress.dart';
import '../../core/data/game_data_manager.dart';

class ProgressionValidator {
  static ProgressionState validateAndRepair(ProgressionState state, GameDataManager dataManager) {
    final levels = Map<String, LevelProgress>.from(state.levels);
    final unlockedWorlds = Set<String>.from(state.unlockedWorlds);
    String? currentLevel = state.currentLevel;

    // 1. Ensure First Level is Unlocked
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

    // 2. Find the earliest uncompleted level (the true next playable level)
    int firstUncompletedNum = 1;
    for (int lvl = 1; lvl <= 147; lvl++) {
      final p = levels['level_$lvl'];
      if (p == null || !p.completed) {
        firstUncompletedNum = lvl;
        break;
      }
    }

    // 3. Ensure the true next playable level is unlocked
    final nextPlayableId = 'level_$firstUncompletedNum';
    if (levels[nextPlayableId] == null) {
      levels[nextPlayableId] = LevelProgress.unlocked(nextPlayableId);
    } else if (!levels[nextPlayableId]!.unlocked) {
      levels[nextPlayableId] = levels[nextPlayableId]!.copyWith(unlocked: true);
    }

    // 4. Repair Impossible States: If level N > firstUncompletedNum is uncompleted but marked unlocked,
    // lock it back up (fixes previous bug where level 51 was accidentally unlocked after level 25)
    for (int lvl = firstUncompletedNum + 1; lvl <= 147; lvl++) {
      final levelId = 'level_$lvl';
      final progress = levels[levelId];
      if (progress != null && progress.unlocked && !progress.completed) {
        levels[levelId] = progress.copyWith(unlocked: false);
      }
    }

    // 5. Ensure currentLevel is valid and points to the next playable level
    final currentNum = int.tryParse(currentLevel?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 1;
    if (currentNum > firstUncompletedNum || levels[currentLevel]?.unlocked != true) {
      currentLevel = nextPlayableId;
    }

    // 6. Ensure worlds containing unlocked or completed levels are unlocked
    for (int lvl = 1; lvl <= firstUncompletedNum; lvl++) {
      final levelId = 'level_$lvl';
      for (final world in allWorlds) {
        if (world.levelIds.contains(levelId)) {
          unlockedWorlds.add(world.worldId);
          break;
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
