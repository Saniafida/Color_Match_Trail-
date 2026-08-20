import 'package:flutter/foundation.dart';
import 'progression_state.dart';
import 'level_progress.dart';
import 'progression_validator.dart';
import 'world_progress.dart';
import '../../core/storage/game_save_manager.dart';
import '../../core/data/game_data_manager.dart';

class ProgressionManager extends ChangeNotifier {
  final GameSaveManager _saveManager;
  final GameDataManager _dataManager;

  ProgressionState _state = ProgressionState.initial();

  ProgressionManager({
    required GameSaveManager saveManager,
    required GameDataManager dataManager,
  })  : _saveManager = saveManager,
        _dataManager = dataManager;

  ProgressionState get state => _state;

  void initialize() {
    final rawData = _saveManager.playerData.campaignProgress;
    
    ProgressionState loadedState;
    if (rawData.isNotEmpty) {
      loadedState = ProgressionState.fromJson(rawData);
    } else {
      loadedState = ProgressionState.initial();
    }

    _state = ProgressionValidator.validateAndRepair(loadedState, _dataManager);
    notifyListeners();
  }

  void saveLevelResult({
    required String levelId,
    required int score,
    required int stars,
    required int movesUsed,
    required int highestCombo,
    required bool completed,
  }) {
    if (!completed) return; // Only process victories for progression

    final Map<String, LevelProgress> newLevels = Map.from(_state.levels);
    final Set<String> newUnlockedWorlds = Set.from(_state.unlockedWorlds);
    
    LevelProgress current = newLevels[levelId] ?? LevelProgress.unlocked(levelId);

    // Update rules: Never downgrade bests
    final newBestScore = score > current.bestScore ? score : current.bestScore;
    final newBestStars = stars > current.stars ? stars : current.stars;
    final newHighestCombo = highestCombo > current.highestCombo ? highestCombo : current.highestCombo;
    
    // For moves, fewer is better, assuming > 0. Or if bestMoves == 0, just set it.
    int newBestMoves = current.bestMoves;
    if (newBestMoves == 0 || (movesUsed < newBestMoves && movesUsed > 0)) {
      newBestMoves = movesUsed;
    }

    newLevels[levelId] = current.copyWith(
      completed: true,
      stars: newBestStars,
      bestScore: newBestScore,
      bestMoves: newBestMoves,
      highestCombo: newHighestCombo,
      completedAt: current.completedAt ?? DateTime.now(),
    );

    // Unlock logic
    String? nextLevelIdToPlay;
    final allWorlds = _dataManager.getAllWorlds();
    for (int w = 0; w < allWorlds.length; w++) {
      final world = allWorlds[w];
      final levelIndex = world.levelIds.indexOf(levelId);
      
      if (levelIndex >= 0) {
        // Unlock next level in this world
        if (levelIndex + 1 < world.levelIds.length) {
          final nextLevelId = world.levelIds[levelIndex + 1];
          nextLevelIdToPlay = nextLevelId;
          final nextProgress = newLevels[nextLevelId];
          if (nextProgress == null || !nextProgress.unlocked) {
            newLevels[nextLevelId] = LevelProgress.unlocked(nextLevelId);
          }
        } 
        // Or check next world unlock
        else if (w + 1 < allWorlds.length) {
          final nextWorld = allWorlds[w + 1];
          // Check stars requirement
          final totalStars = _calculateTotalStars(newLevels);
          if (totalStars >= nextWorld.unlockRequirement) {
            newUnlockedWorlds.add(nextWorld.worldId);
            if (nextWorld.levelIds.isNotEmpty) {
              final nextLevelId = nextWorld.levelIds.first;
              nextLevelIdToPlay = nextLevelId;
              final nextProgress = newLevels[nextLevelId];
              if (nextProgress == null || !nextProgress.unlocked) {
                newLevels[nextLevelId] = LevelProgress.unlocked(nextLevelId);
              }
            }
          }
        }
        break;
      }
    }

    _state = _state.copyWith(
      levels: newLevels,
      unlockedWorlds: newUnlockedWorlds,
      currentLevel: nextLevelIdToPlay ?? _state.currentLevel,
    );

    _save();
    notifyListeners();
  }

  void setCurrentLevel(String levelId) {
    if (_state.levels[levelId]?.unlocked ?? false) {
      _state = _state.copyWith(currentLevel: levelId);
      _save();
      notifyListeners();
    }
  }

  int _calculateTotalStars(Map<String, LevelProgress> levels) {
    return levels.values.fold(0, (sum, progress) => sum + progress.stars);
  }

  WorldProgress getWorldProgress(String worldId) {
    final world = _dataManager.getWorld(worldId);
    if (world == null) {
      return WorldProgress(
        worldId: worldId,
        unlocked: false,
        completedLevels: 0,
        totalLevels: 0,
        earnedStars: 0,
        totalStars: 0,
      );
    }

    int completedLevels = 0;
    int earnedStars = 0;

    for (final levelId in world.levelIds) {
      final prog = _state.levels[levelId];
      if (prog != null && prog.completed) {
        completedLevels++;
        earnedStars += prog.stars;
      }
    }

    return WorldProgress(
      worldId: worldId,
      unlocked: _state.unlockedWorlds.contains(worldId),
      completedLevels: completedLevels,
      totalLevels: world.levelIds.length,
      earnedStars: earnedStars,
      totalStars: world.levelIds.length * 3, // Assuming 3 max per level
    );
  }

  void _save() {
    _saveManager.updateCampaignProgress(_state.toJson());
  }

  void resetProgression() {
    _state = ProgressionValidator.validateAndRepair(ProgressionState.initial(), _dataManager);
    _save();
    notifyListeners();
  }
}
