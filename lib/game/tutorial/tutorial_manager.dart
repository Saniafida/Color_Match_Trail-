import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/storage/game_save_manager.dart';
import '../../core/data/game_data_manager.dart';
import 'tutorial_state.dart';
import 'tutorial_progress.dart';
import 'tutorial_definition.dart';
import 'tutorial_step_definition.dart';

class TutorialManager extends ChangeNotifier {
  final GameSaveManager saveManager;
  final GameDataManager dataManager;

  TutorialState _state = TutorialState.notStarted;
  TutorialState get state => _state;

  TutorialProgress _progress = const TutorialProgress();
  TutorialProgress get progress => _progress;

  TutorialDefinition? _activeTutorial;
  TutorialDefinition? get activeTutorial => _activeTutorial;

  TutorialManager({
    required this.saveManager,
    required this.dataManager,
  });

  bool get isActive => _state == TutorialState.active || _state == TutorialState.waitingForAction;
  
  TutorialStepDefinition? get currentStep {
    if (_activeTutorial == null || _progress.currentStep >= _activeTutorial!.steps.length) {
      return null;
    }
    return _activeTutorial!.steps[_progress.currentStep];
  }

  Future<void> initialize() async {
    await _loadProgress();
  }

  Future<void> _loadProgress() async {
    final dynamic savedData = saveManager.playerData.onboarding;
    if (savedData != null && savedData is Map<String, dynamic> && savedData.isNotEmpty) {
      _progress = TutorialProgress.fromJson(savedData);
    } else {
      _progress = const TutorialProgress();
    }

    if (_progress.currentTutorialId != null) {
      // Resume active tutorial
      _activeTutorial = await _loadTutorialDefinition(_progress.currentTutorialId!);
      if (_activeTutorial != null) {
        _state = TutorialState.active;
      } else {
        _progress = _progress.copyWith(clearCurrent: true);
        _state = TutorialState.notStarted;
        await _saveProgress();
      }
    }
  }

  Future<void> _saveProgress() async {
    saveManager.updateOnboarding(_progress.toJson());
    notifyListeners();
  }

  Future<TutorialDefinition?> _loadTutorialDefinition(String id) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/tutorial/$id.json');
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return TutorialDefinition.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Error loading tutorial definition $id: $e');
    }
    return null;
  }

  Future<void> checkAndStartTutorial(String levelId) async {
    if (isActive) return;

    // Check if we need to start tutorial_main
    if (levelId == '1' && !_progress.completedTutorials.contains('main_mechanics') && !_progress.skippedTutorials.contains('main_mechanics')) {
      await _startTutorial('main_mechanics');
    } else if (levelId == '3' && !_progress.completedTutorials.contains('boosters_intro') && !_progress.skippedTutorials.contains('boosters_intro')) {
      await _startTutorial('boosters_intro');
    }
  }

  Future<void> _startTutorial(String tutorialId) async {
    _activeTutorial = await _loadTutorialDefinition(tutorialId);
    if (_activeTutorial != null) {
      _progress = _progress.copyWith(
        currentTutorialId: tutorialId,
        currentStep: 0,
      );
      _state = TutorialState.active;
      await _saveProgress();
    }
  }

  void advanceStep() {
    if (!isActive || _activeTutorial == null) return;

    if (_progress.currentStep + 1 < _activeTutorial!.steps.length) {
      _progress = _progress.copyWith(currentStep: _progress.currentStep + 1);
      _state = TutorialState.active; // Reset to active from waitingForAction
      _saveProgress();
    } else {
      completeTutorial();
    }
  }

  void completeTutorial() {
    if (_activeTutorial == null) return;

    final completed = List<String>.from(_progress.completedTutorials);
    if (!completed.contains(_activeTutorial!.tutorialId)) {
      completed.add(_activeTutorial!.tutorialId);
    }

    // Grant reward if needed
    // if (_activeTutorial!.rewardId != null && _activeTutorial!.rewardId != "none") {
    //   rewardManager.grantReward(_activeTutorial!.rewardId!);
    // }

    _state = TutorialState.completed;
    _progress = _progress.copyWith(
      completedTutorials: completed,
      clearCurrent: true,
    );
    _activeTutorial = null;
    _saveProgress();
  }

  void skipTutorial() {
    if (_activeTutorial == null) return;

    final skipped = List<String>.from(_progress.skippedTutorials);
    if (!skipped.contains(_activeTutorial!.tutorialId)) {
      skipped.add(_activeTutorial!.tutorialId);
    }

    _state = TutorialState.skipped;
    _progress = _progress.copyWith(
      skippedTutorials: skipped,
      clearCurrent: true,
    );
    _activeTutorial = null;
    _saveProgress();
  }

  void replayTutorial(String tutorialId) {
    final skipped = List<String>.from(_progress.skippedTutorials);
    skipped.remove(tutorialId);
    _progress = _progress.copyWith(skippedTutorials: skipped);
    _startTutorial(tutorialId);
  }

  // Used by the UI/Game logic to validate an action
  bool validateAction(String actionType, {String? targetId}) {
    if (!isActive || currentStep == null) return true;

    final step = currentStep!;
    
    // If the required action is 'continue', it means it just needs the user to tap 'Next'
    if (step.requiredAction == 'continue') {
      return true; // We don't block other logic, but maybe we should block the board?
    }

    // If the step requires a specific action, validate it
    if (step.requiredAction == actionType) {
      if (step.targetId != null && step.targetId != targetId) {
        return false;
      }
      return true;
    }
    
    // If it's a different action, block it if it's strict
    return false;
  }
}
