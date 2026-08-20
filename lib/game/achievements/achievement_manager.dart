import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';

import 'achievement_definition.dart';
import 'achievement_progress.dart';
import 'achievement_storage.dart';
import 'achievement_type.dart';
import '../statistics/statistics_manager.dart';
import '../rewards/reward_manager.dart';
import '../rewards/reward_definition.dart';
import '../settings/settings_manager.dart';

class AchievementManager extends ChangeNotifier {
  final AchievementStorage storage;
  final StatisticsManager statisticsManager;
  final RewardManager rewardManager;
  final SettingsManager settingsManager;

  final List<AchievementDefinition> _definitions = [];
  Map<String, AchievementProgress> _progress = {};
  
  // Notification queue
  final Queue<AchievementDefinition> _unlockQueue = Queue();
  final StreamController<AchievementDefinition> _unlockStreamController = StreamController.broadcast();
  Stream<AchievementDefinition> get unlockStream => _unlockStreamController.stream;

  AchievementManager({
    required this.storage,
    required this.statisticsManager,
    required this.rewardManager,
    required this.settingsManager,
  });

  List<AchievementDefinition> get definitions => List.unmodifiable(_definitions);
  Map<String, AchievementProgress> get progress => Map.unmodifiable(_progress);

  Future<void> initialize(List<AchievementDefinition> defs) async {
    _definitions.clear();
    _definitions.addAll(defs);
    
    _progress = await storage.loadAllProgress();
    
    // Create missing progress
    bool missing = false;
    for (var def in _definitions) {
      if (!_progress.containsKey(def.id)) {
        _progress[def.id] = AchievementProgress(
          achievementId: def.id,
          currentValue: 0,
          targetValue: def.targetValue,
          unlocked: false,
          rewardClaimed: false,
        );
        missing = true;
      }
    }
    
    if (missing) {
      await storage.saveAllProgress(_progress.values.toList());
    }

    statisticsManager.addListener(_onStatisticsChanged);
    notifyListeners();
  }

  @override
  void dispose() {
    statisticsManager.removeListener(_onStatisticsChanged);
    _unlockStreamController.close();
    super.dispose();
  }

  void _onStatisticsChanged() {
    _evaluateAchievements();
  }

  void _evaluateAchievements() {
    final stats = statisticsManager.stats;
    bool changed = false;

    for (var def in _definitions) {
      if (!def.enabled) continue;
      
      final currentProg = _progress[def.id]!;
      if (currentProg.unlocked) continue;

      int currentVal = 0;
      switch (def.achievementType) {
        case AchievementType.levelsCompleted:
          currentVal = stats.levelsCompleted;
          break;
        case AchievementType.starsEarned:
          currentVal = stats.totalStars;
          break;
        case AchievementType.scoreReached:
          currentVal = stats.highestScore;
          break;
        case AchievementType.blocksCleared:
          currentVal = stats.totalBlocksCleared;
          break;
        case AchievementType.comboReached:
          currentVal = stats.highestCombo;
          break;
        case AchievementType.cascadesAchieved:
          currentVal = stats.highestCascade;
          break;
        case AchievementType.boostersUsed:
          currentVal = stats.totalBoostersUsed;
          break;
        case AchievementType.dailyChallengesCompleted:
          currentVal = stats.totalDailyChallenges;
          break;
        case AchievementType.eventsCompleted:
          currentVal = stats.totalEventsCompleted;
          break;
        case AchievementType.itemsCollected:
          // Depends on inventory, simplified for now
          currentVal = currentProg.currentValue;
          break;
      }

      if (currentVal > currentProg.currentValue) {
        bool newlyUnlocked = currentVal >= def.targetValue;
        _progress[def.id] = currentProg.copyWith(
          currentValue: currentVal > def.targetValue ? def.targetValue : currentVal,
          unlocked: newlyUnlocked,
          unlockedAt: newlyUnlocked ? DateTime.now() : null,
        );
        
        changed = true;

        if (newlyUnlocked) {
          _handleUnlock(def);
        }
      }
    }

    if (changed) {
      storage.saveAllProgress(_progress.values.toList());
      notifyListeners();
    }
  }

  void _handleUnlock(AchievementDefinition def) {
    // 1. Grant Reward
    if (def.rewardId != null && def.rewardAmount > 0) {
      if (def.rewardId == 'coins') {
        rewardManager.grantReward(
          RewardDefinition(id: def.id, type: RewardType.coins, amount: def.rewardAmount, source: 'achievement'),
          uniqueClaimId: 'achieve_${def.id}',
        );
      } else {
        // Booster fallback
        rewardManager.grantReward(
          RewardDefinition(id: def.id, type: RewardType.booster, itemId: def.rewardId, amount: def.rewardAmount, source: 'achievement'),
          uniqueClaimId: 'achieve_${def.id}',
        );
      }
      _progress[def.id] = _progress[def.id]!.copyWith(rewardClaimed: true);
    }

    // 2. Notifications
    if (settingsManager.state.notificationsEnabled) {
      _unlockQueue.add(def);
      _processQueue();
    }
  }

  bool _isProcessingQueue = false;
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _unlockQueue.isEmpty) return;
    
    _isProcessingQueue = true;
    while (_unlockQueue.isNotEmpty) {
      final def = _unlockQueue.removeFirst();
      _unlockStreamController.add(def);
      
      // Wait for UI popup duration to avoid overlap
      await Future.delayed(const Duration(seconds: 4));
    }
    _isProcessingQueue = false;
  }
}
