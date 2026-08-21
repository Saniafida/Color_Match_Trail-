import 'dart:async';
import 'package:flutter/widgets.dart';

import 'milestone_definition.dart';
import 'milestone_progress.dart';
import 'achievement_event.dart';
import '../rewards/reward_manager.dart';
import '../rewards/reward_definition.dart';
import '../../core/storage/game_save_manager.dart';

class MilestoneManager extends ChangeNotifier {
  final GameSaveManager saveManager;
  final RewardManager rewardManager;

  final List<MilestoneDefinition> _definitions = [];
  Map<String, MilestoneProgress> _progress = {};

  final StreamController<MilestoneDefinition> _unlockStreamController = StreamController.broadcast();
  Stream<MilestoneDefinition> get unlockStream => _unlockStreamController.stream;

  MilestoneManager({
    required this.saveManager,
    required this.rewardManager,
  });

  List<MilestoneDefinition> get definitions => List.unmodifiable(_definitions);
  Map<String, MilestoneProgress> get progress => Map.unmodifiable(_progress);

  Future<void> initialize(List<MilestoneDefinition> defs) async {
    _definitions.clear();
    _definitions.addAll(defs);
    
    _progress = _loadAllProgress();
    
    // Create missing progress
    bool missing = false;
    for (var def in _definitions) {
      if (!_progress.containsKey(def.milestoneId)) {
        _progress[def.milestoneId] = MilestoneProgress(
          milestoneId: def.milestoneId,
          currentValue: 0,
          targetValue: def.targetValue,
          completed: false,
          rewardGranted: false,
        );
        missing = true;
      }
    }
    
    if (missing) {
      _saveAllProgress();
    }

    notifyListeners();
  }

  Map<String, MilestoneProgress> _loadAllProgress() {
    final state = saveManager.playerData.milestones;
    final Map<String, MilestoneProgress> result = {};
    for (var key in state.keys) {
      try {
        result[key] = MilestoneProgress.fromJson(state[key]);
      } catch (e) {
        // ignore
      }
    }
    return result;
  }

  void _saveAllProgress() {
    final state = Map<String, dynamic>.from(saveManager.playerData.milestones);
    for (var p in _progress.values) {
      state[p.milestoneId] = p.toJson();
    }
    saveManager.updateMilestones(state);
  }

  void _saveProgress(MilestoneProgress prog) {
    final state = Map<String, dynamic>.from(saveManager.playerData.milestones);
    state[prog.milestoneId] = prog.toJson();
    saveManager.updateMilestones(state);
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
      
      final currentProg = _progress[def.milestoneId];
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
        newVal += 1; 
      } else if (event is LevelCompletedEvent && def.targetType == 'stars_earned') {
        newVal += event.stars;
      } else if (event is BoosterUsedEvent && def.targetType == 'boosters_used') {
        newVal += 1;
      } else if (event is ChallengeCompletedEvent && def.targetType == 'challenges_completed') {
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

        _progress[def.milestoneId] = updatedProg;
        _saveProgress(updatedProg);
        
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

  Future<void> _grantReward(MilestoneDefinition def, MilestoneProgress prog) async {
    if (prog.rewardGranted || def.rewardId == null || def.rewardId!.isEmpty) return;

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
      source: 'milestone',
    );

    await rewardManager.grantReward(rewardDef, uniqueClaimId: 'milestone_${def.milestoneId}');
    
    final updatedProg = prog.copyWith(rewardGranted: true);
    _progress[def.milestoneId] = updatedProg;
    _saveProgress(updatedProg);
    notifyListeners();
  }
}
