import 'package:flutter/foundation.dart';
import 'progression_state.dart';
import 'level_progress.dart';
import 'progression_validator.dart';
import 'world_progress.dart';
import 'level_unlock_validator.dart';
import 'world_unlock_validator.dart';
import '../../core/storage/game_save_manager.dart';
import '../../core/data/game_data_manager.dart';
import '../rewards/reward_manager.dart';
import '../rewards/reward_definition.dart';
import '../achievements/achievement_manager.dart';
import '../achievements/milestone_manager.dart';
import '../achievements/achievement_event.dart';

class ProgressionManager extends ChangeNotifier {
  final GameSaveManager _saveManager;
  final GameDataManager _dataManager;
  RewardManager? _rewardManager;
  AchievementManager? _achievementManager;
  MilestoneManager? _milestoneManager;

  ProgressionState _state = ProgressionState.initial();

  ProgressionManager({
    required GameSaveManager saveManager,
    required GameDataManager dataManager,
    RewardManager? rewardManager,
    AchievementManager? achievementManager,
    MilestoneManager? milestoneManager,
  })  : _saveManager = saveManager,
        _dataManager = dataManager,
        _rewardManager = rewardManager,
        _achievementManager = achievementManager,
        _milestoneManager = milestoneManager;

  void setDependencies({
    RewardManager? rewardManager,
    AchievementManager? achievementManager,
    MilestoneManager? milestoneManager,
  }) {
    if (rewardManager != null) _rewardManager = rewardManager;
    if (achievementManager != null) _achievementManager = achievementManager;
    if (milestoneManager != null) _milestoneManager = milestoneManager;
  }

  ProgressionState get state => _state;

  List<LevelProgress> get unlockedLevels => _state.levels.values.where((l) => l.unlocked).toList();
  List<LevelProgress> get completedLevels => _state.levels.values.where((l) => l.completed).toList();
  
  int get totalStars => _state.levels.values.fold(0, (sum, l) => sum + l.bestStars);

  String get currentPlayableLevel => getNextPlayableLevel();

  bool get isCampaignCompleted {
    final allWorlds = _dataManager.getAllWorlds();
    if (allWorlds.isEmpty) return false;
    for (final world in allWorlds) {
      for (final lvlId in world.levelIds) {
        final prog = _state.levels[lvlId];
        if (prog == null || !prog.completed) return false;
      }
    }
    return true;
  }

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

  /// Validates if a level can currently be played
  LevelUnlockValidationResult validateLevelAccess(String levelId) {
    return LevelUnlockValidator.validate(
      levelId: levelId,
      state: _state,
      dataManager: _dataManager,
    );
  }

  bool canPlayLevel(String levelId) {
    return validateLevelAccess(levelId).isUnlocked;
  }

  /// Validates if a world can currently be accessed
  WorldUnlockValidationResult validateWorldAccess(String worldId) {
    return WorldUnlockValidator.validate(
      worldId: worldId,
      state: _state,
      dataManager: _dataManager,
    );
  }

  bool canAccessWorld(String worldId) {
    return validateWorldAccess(worldId).isUnlocked;
  }

  /// Recommends the next playable level for Home Continue button
  String getNextPlayableLevel() {
    final allWorlds = _dataManager.getAllWorlds();
    if (allWorlds.isEmpty) return _state.currentLevel ?? 'level_1';

    for (final world in allWorlds) {
      if (_state.unlockedWorlds.contains(world.worldId)) {
        for (final levelId in world.levelIds) {
          final progress = _state.levels[levelId];
          if (progress == null || !progress.completed) {
            if (progress?.unlocked ?? false) {
              return levelId;
            }
          }
        }
      }
    }

    // If all completed or none found, fallback to current level or first level
    return _state.currentLevel ?? (allWorlds.first.levelIds.isNotEmpty ? allWorlds.first.levelIds.first : 'level_1');
  }

  Future<void> saveLevelResult({
    required String levelId,
    required int score,
    required int stars,
    required int movesUsed,
    required int highestCombo,
    required bool completed,
  }) async {
    final Map<String, LevelProgress> newLevels = Map.from(_state.levels);
    final Set<String> newUnlockedWorlds = Set.from(_state.unlockedWorlds);
    
    LevelProgress current = newLevels[levelId] ?? LevelProgress.unlocked(levelId);
    final wasAlreadyCompleted = current.completed;
    final now = DateTime.now();

    // Increment attempt count and record last played
    final newAttemptCount = current.attemptCount + 1;

    if (!completed) {
      // Record failed attempt without resetting progress
      newLevels[levelId] = current.copyWith(
        attemptCount: newAttemptCount,
        lastPlayed: now,
      );
      _state = _state.copyWith(levels: newLevels);
      _save();
      notifyListeners();
      return;
    }

    // Safety rule: Never downgrade bests
    final newBestScore = score > current.bestScore ? score : current.bestScore;
    final newBestStars = stars > current.bestStars ? stars : current.bestStars;
    final newHighestCombo = highestCombo > current.highestCombo ? highestCombo : current.highestCombo;
    
    int newBestMoves = current.bestMoves;
    if (newBestMoves == 0 || (movesUsed < newBestMoves && movesUsed > 0)) {
      newBestMoves = movesUsed;
    }

    newLevels[levelId] = current.copyWith(
      completed: true,
      bestStars: newBestStars,
      bestScore: newBestScore,
      bestMoves: newBestMoves,
      highestCombo: newHighestCombo,
      attemptCount: newAttemptCount,
      firstCompleted: current.firstCompleted ?? now,
      lastPlayed: now,
    );

    // 1. First-time level completion reward
    if (!wasAlreadyCompleted && _rewardManager != null) {
      final rewardClaimId = 'level_first_win_$levelId';
      final firstWinCoins = _dataManager.balanceConfig.levelFirstStarCoins;
      if (firstWinCoins > 0) {
        await _rewardManager!.grantReward(
          RewardDefinition(
            id: 'reward_first_win_$levelId',
            type: RewardType.coins,
            amount: firstWinCoins,
            source: 'progression',
          ),
          uniqueClaimId: rewardClaimId,
        );
      }
    }

    // 2. Unlock Next Level or Next World
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
          final totalEarnedStars = newLevels.values.fold(0, (sum, lp) => sum + lp.bestStars);
          if (totalEarnedStars >= nextWorld.unlockRequirement) {
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

        // 3. Check world completion reward
        final isWorldNowComplete = world.levelIds.every((id) => newLevels[id]?.completed ?? false);
        if (isWorldNowComplete && _rewardManager != null) {
          final worldClaimId = 'world_complete_${world.worldId}';
          if (world.rewardCoins > 0) {
            await _rewardManager!.grantReward(
              RewardDefinition(
                id: 'reward_${world.worldId}',
                type: RewardType.coins,
                amount: world.rewardCoins,
                source: 'progression',
              ),
              uniqueClaimId: worldClaimId,
            );
          }
          _achievementManager?.processEvent(WorldCompletedEvent(world.worldId));
          _milestoneManager?.processEvent(WorldCompletedEvent(world.worldId));
        }

        break;
      }
    }

    _state = _state.copyWith(
      levels: newLevels,
      unlockedWorlds: newUnlockedWorlds,
      currentLevel: nextLevelIdToPlay ?? _state.currentLevel,
    );

    // 4. Achievement & Milestone dispatch
    final levelEvent = LevelCompletedEvent(levelId, stars);
    _achievementManager?.processEvent(levelEvent);
    _milestoneManager?.processEvent(levelEvent);

    _save();
    notifyListeners();
  }

  void setCurrentLevel(String levelId) {
    if (canPlayLevel(levelId)) {
      _state = _state.copyWith(currentLevel: levelId);
      _save();
      notifyListeners();
    }
  }

  WorldProgress getWorldProgress(String worldId) {
    final world = _dataManager.getWorld(worldId);
    if (world == null) {
      return WorldProgress(
        worldId: worldId,
        unlocked: false,
        completed: false,
        completedLevels: 0,
        totalLevels: 0,
        stars: 0,
        maxStars: 0,
      );
    }

    int completedLevels = 0;
    int earnedStars = 0;

    for (final levelId in world.levelIds) {
      final prog = _state.levels[levelId];
      if (prog != null && prog.completed) {
        completedLevels++;
        earnedStars += prog.bestStars;
      }
    }

    final isWorldComplete = completedLevels >= world.levelIds.length && world.levelIds.isNotEmpty;

    return WorldProgress(
      worldId: worldId,
      unlocked: _state.unlockedWorlds.contains(worldId),
      completed: isWorldComplete,
      completedLevels: completedLevels,
      totalLevels: world.levelIds.length,
      stars: earnedStars,
      maxStars: world.levelIds.length * 3,
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
