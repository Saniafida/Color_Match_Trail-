import 'dart:async';
import 'package:flutter/widgets.dart';

import 'achievement_definition.dart';
import 'achievement_progress.dart';
import 'achievement_storage.dart';
import 'achievement_event.dart';
import '../rewards/reward_manager.dart';
import '../rewards/reward_definition.dart';

class AchievementManager extends ChangeNotifier {
  final AchievementStorage storage;
  final RewardManager rewardManager;

  final List<AchievementDefinition> _definitions = [];
  Map<String, AchievementProgress> _progress = {};

  final StreamController<AchievementDefinition> _unlockStreamController = StreamController.broadcast();
  Stream<AchievementDefinition> get unlockStream => _unlockStreamController.stream;

  AchievementManager({
    required this.storage,
    required this.rewardManager,
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
      if (!_progress.containsKey(def.achievementId)) {
        _progress[def.achievementId] = AchievementProgress(
          achievementId: def.achievementId,
          currentValue: 0,
          targetValue: def.targetValue,
          completed: false,
          rewardGranted: false,
        );
        missing = true;
      }
    }
    
    if (missing) {
      await storage.saveAllProgress(_progress.values.toList());
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _unlockStreamController.close();
    super.dispose();
  }

  Future<void> processEvent(AchievementEvent event) async {
    bool changed = false;

    for (var def in _definitions) {
      if (!def.enabled) continue;
      
      final currentProg = _progress[def.achievementId];
      if (currentProg == null || currentProg.completed) continue;

      int newVal = currentProg.currentValue;

      // Event parsing based on targetType
      if (event is BlockBlastEvent && def.targetType == 'blocks_cleared') {
        newVal += event.count;
      } else if (event is BlockBlastEvent && def.targetType == 'large_blasts' && event.count >= 6) {
        newVal += 1;
      } else if (event is BlockBlastEvent && def.targetType == 'mega_blasts' && event.isMegaBlast) {
        newVal += 1;
      } else if (event is ComboEvent && def.targetType == 'combos') {
        if (event.comboMultiplier >= def.targetValue) {
          newVal = def.targetValue;
        }
      } else if (event is LevelCompletedEvent && def.targetType == 'levels_completed') {
        newVal += 1; // Assuming each level is uniquely completed? Or just raw count.
      } else if (event is LevelCompletedEvent && def.targetType == 'stars_earned') {
        newVal += event.stars;
      } else if (event is BoosterUsedEvent && def.targetType == 'boosters_used') {
        newVal += 1;
      } else if (event is ChallengeCompletedEvent && def.targetType == 'challenges_completed') {
        newVal += 1;
      } else if (event is WorldCompletedEvent && def.targetType == 'worlds_completed') {
        newVal += 1;
      }

      if (newVal != currentProg.currentValue) {
        bool completed = false;
        if (newVal >= def.targetValue) {
          newVal = def.targetValue;
          completed = true;
        }

        final updatedProg = currentProg.copyWith(
          currentValue: newVal,
          completed: completed,
          completedAt: completed ? DateTime.now() : null,
        );

        _progress[def.achievementId] = updatedProg;
        await storage.saveProgress(updatedProg);
        
        if (completed) {
          _unlockStreamController.add(def);
          _grantReward(def, updatedProg);
        }

        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> _grantReward(AchievementDefinition def, AchievementProgress prog) async {
    if (prog.rewardGranted || def.rewardId == null || def.rewardId!.isEmpty) return;

    // Based on ID format 'reward_coins_50' or 'reward_booster_hammer_1'
    RewardType type = RewardType.coins;
    int amount = 1;
    String? itemId;
    if (def.rewardId!.contains('coins')) {
      type = RewardType.coins;
      amount = int.tryParse(def.rewardId!.split('_').last) ?? 10;
    } else if (def.rewardId!.contains('booster')) {
      type = RewardType.booster;
      final parts = def.rewardId!.split('_');
      itemId = parts[2];
      amount = int.tryParse(parts.last) ?? 1;
    }

    final rewardDef = RewardDefinition(
      id: def.rewardId!,
      type: type,
      amount: amount,
      itemId: itemId,
      source: 'achievement',
    );

    await rewardManager.grantReward(rewardDef, uniqueClaimId: 'achievement_${def.achievementId}');
    
    final updatedProg = prog.copyWith(rewardGranted: true);
    _progress[def.achievementId] = updatedProg;
    await storage.saveProgress(updatedProg);
    notifyListeners();
  }
}
