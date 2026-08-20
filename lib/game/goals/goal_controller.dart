import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../blast/blast.dart';
import '../score/score.dart';
import '../cascade/cascade.dart';
import '../specials/special.dart';
import '../boosters/booster.dart';
import 'goal_state.dart';
import 'goal_event_source.dart';
import 'goal_progress_event.dart';
import 'goal_completed_event.dart';
import 'dart:math' as math;

class GoalController extends ChangeNotifier {
  final Map<String, GoalDefinition> _definitions = {};
  final Map<String, GoalState> _states = {};
  
  final StreamController<GoalProgressEvent> _progressController = StreamController<GoalProgressEvent>.broadcast(sync: true);
  Stream<GoalProgressEvent> get onProgress => _progressController.stream;

  final StreamController<GoalCompletedEvent> _completedController = StreamController<GoalCompletedEvent>.broadcast(sync: true);
  Stream<GoalCompletedEvent> get onCompleted => _completedController.stream;

  List<GoalState> get states => _states.values.toList();
  GoalDefinition getDefinition(String id) => _definitions[id]!;
  
  bool get allRequiredGoalsCompleted {
    if (_states.isEmpty) return false; // If no goals loaded, arguably false. Or maybe true if level has no goals? Usually false.
    final requiredGoals = _states.values.where((g) => !g.isOptional);
    if (requiredGoals.isEmpty) return false;
    return requiredGoals.every((g) => g.completed);
  }

  bool get allGoalsCompleted {
    if (_states.isEmpty) return false;
    return _states.values.every((g) => g.completed);
  }

  void initialize(List<GoalDefinition> goals) {
    _definitions.clear();
    _states.clear();
    
    for (var def in goals) {
      if (def.targetAmount <= 0) {
        continue;
      }
      
      _definitions[def.id] = def;
      _states[def.id] = GoalState(
        goalId: def.id,
        currentAmount: 0,
        targetAmount: def.targetAmount,
        completed: false,
        isOptional: def.isOptional,
      );
    }
    
    notifyListeners();
  }

  void resetGoals() {
    for (var key in _states.keys) {
      final state = _states[key]!;
      _states[key] = state.copyWith(currentAmount: 0, completed: false);
    }
    notifyListeners();
  }

  void _updateGoalProgress(String goalId, int amountAdded, GoalEventSource source) {
    if (amountAdded <= 0) return;
    
    final def = _definitions[goalId];
    final state = _states[goalId];
    if (def == null || state == null || state.completed) return;
    
    final previousAmount = state.currentAmount;
    final newRawAmount = previousAmount + amountAdded;
    final newAmount = math.min(newRawAmount, def.targetAmount);
    final actuallyAdded = newAmount - previousAmount;
    
    final completed = newAmount >= def.targetAmount;
    
    _states[goalId] = state.copyWith(
      currentAmount: newAmount,
      completed: completed,
    );
    
    _progressController.add(GoalProgressEvent(
      goalId: goalId,
      previousAmount: previousAmount,
      newAmount: newAmount,
      amountAdded: actuallyAdded,
      source: source,
      completed: completed,
    ));
    
    if (completed) {
      _completedController.add(GoalCompletedEvent(
        goalId: goalId,
        goalType: def.type,
        finalAmount: newAmount,
        targetAmount: def.targetAmount,
      ));
    }
    
    notifyListeners();
  }

  // --- Event Consumers ---

  void onBlastResult(BlastResult result) {
    if (!result.success || result.destroyedCount == 0) return;
    
    GoalEventSource source;
    switch (result.source) {
      case DestructionSource.playerMatch:
        source = GoalEventSource.playerMatch;
        break;
      case DestructionSource.cascade:
        source = GoalEventSource.cascade;
        break;
      case DestructionSource.special:
      case DestructionSource.specialCombination:
        source = GoalEventSource.special;
        break;
      case DestructionSource.booster:
        source = GoalEventSource.booster;
        break;
    }
    
    for (var def in _definitions.values) {
      if (def.type == GoalType.clearBlocks) {
        _updateGoalProgress(def.id, result.destroyedCount, source);
      } else if (def.type == GoalType.clearColor) {
        // We assume result.color matches the blocks destroyed. 
        // Note: For a mixed-color bomb blast, the blast result currently just passes the initial match color or red if none.
        // For a more robust implementation, we would need the breakdown of colors destroyed.
        // Based on the prompt: "Only destroyed blocks of the exact configured color count."
        if (result.color == def.color) {
          _updateGoalProgress(def.id, result.destroyedCount, source);
        }
      }
    }
  }

  void onScoreEvent(ScoreEvent event) {
    if (event.pointsAdded <= 0) return;
    for (var def in _definitions.values) {
      if (def.type == GoalType.score) {
        _updateGoalProgress(def.id, event.pointsAdded, GoalEventSource.score);
      }
    }
  }

  void onCascadeResult(CascadeResult result) {
    if (result.cascadeLevel <= 0) return;
    for (var def in _definitions.values) {
      if (def.type == GoalType.reachCascade) {
        // If they reached level 3 and target is 3, they complete it.
        // Instead of adding linearly, we just add enough to complete it if it's high enough.
        // Or if it's "Perform X cascades", maybe we add 1 per cascade sequence?
        // Prompt says: "If goal: Reach Cascade 4, and result: cascadeLevel = 5, Goal becomes: completed."
        // So we add targetAmount to complete it instantly.
        if (result.cascadeLevel >= def.targetAmount) {
          final state = _states[def.id];
          if (state != null && !state.completed) {
            _updateGoalProgress(def.id, def.targetAmount - state.currentAmount, GoalEventSource.cascade);
          }
        }
      }
    }
  }

  void onSpecialCreation(SpecialCreationResult result) {
    if (!result.created || result.type == SpecialBlockType.none) return;
    for (var def in _definitions.values) {
      if (def.type == GoalType.createSpecial && def.specialType == result.type) {
        _updateGoalProgress(def.id, 1, GoalEventSource.specialCreation);
      }
    }
  }

  void onSpecialActivation(SpecialActivationResult result) {
    if (!result.success) return;
    for (var def in _definitions.values) {
      if (def.type == GoalType.activateSpecial && def.specialType == result.specialType) {
        _updateGoalProgress(def.id, 1, GoalEventSource.special);
      }
    }
  }

  void onBoosterUse(BoosterUseResult result) {
    if (!result.success || !result.consumed) return;
    for (var def in _definitions.values) {
      if (def.type == GoalType.useBooster && def.boosterType == result.boosterType) {
        _updateGoalProgress(def.id, 1, GoalEventSource.booster);
      }
    }
  }

  @override
  void dispose() {
    _progressController.close();
    _completedController.close();
    super.dispose();
  }
}
