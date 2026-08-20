import 'package:flutter/foundation.dart';
import 'onboarding_state.dart';
import 'onboarding_step.dart';
import 'onboarding_storage.dart';

class OnboardingManager extends ChangeNotifier {
  final OnboardingStorage storage;

  OnboardingState _state = OnboardingState.defaults();

  OnboardingManager({required this.storage});

  OnboardingState get state => _state;
  bool get isCompleted => _state.completed || _state.skipped;
  bool get isOnboardingRequired => !isCompleted;

  void initialize() {
    _state = storage.load();
  }

  Future<void> advanceStep() async {
    final allSteps = OnboardingStep.values;
    final currentIndex = allSteps.indexOf(_state.currentStep);

    if (currentIndex < 0) return;

    if (currentIndex >= allSteps.length - 2) {
      // We've reached OnboardingStep.complete
      await _markComplete();
      return;
    }

    final nextStep = allSteps[currentIndex + 1];
    _state = _state.copyWith(
      isFirstLaunch: false,
      currentStep: nextStep,
    );
    await storage.save(_state);
    notifyListeners();
  }

  Future<void> _markComplete() async {
    _state = _state.copyWith(
      completed: true,
      currentStep: OnboardingStep.complete,
      isFirstLaunch: false,
    );
    await storage.save(_state);
    notifyListeners();
  }

  Future<void> skip() async {
    _state = _state.copyWith(
      skipped: true,
      isFirstLaunch: false,
    );
    await storage.save(_state);
    notifyListeners();
  }

  Future<void> replayTutorial() async {
    // Replay does NOT reset campaign/coins/achievements
    _state = OnboardingState(
      isFirstLaunch: false,
      currentStep: OnboardingStep.connectColors,
      completed: false,
      skipped: false,
      tutorialVersion: _state.tutorialVersion,
    );
    await storage.save(_state);
    notifyListeners();
  }
}
