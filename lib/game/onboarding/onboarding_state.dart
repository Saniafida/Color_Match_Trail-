import 'onboarding_step.dart';

const int currentTutorialVersion = 1;

class OnboardingState {
  final bool isFirstLaunch;
  final OnboardingStep currentStep;
  final bool completed;
  final bool skipped;
  final int tutorialVersion;

  const OnboardingState({
    this.isFirstLaunch = true,
    this.currentStep = OnboardingStep.connectColors,
    this.completed = false,
    this.skipped = false,
    this.tutorialVersion = currentTutorialVersion,
  });

  OnboardingState copyWith({
    bool? isFirstLaunch,
    OnboardingStep? currentStep,
    bool? completed,
    bool? skipped,
    int? tutorialVersion,
  }) {
    return OnboardingState(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      currentStep: currentStep ?? this.currentStep,
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
      tutorialVersion: tutorialVersion ?? this.tutorialVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFirstLaunch': isFirstLaunch,
      'currentStep': currentStep.name,
      'completed': completed,
      'skipped': skipped,
      'tutorialVersion': tutorialVersion,
    };
  }

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    final stepName = json['currentStep'] as String? ?? OnboardingStep.connectColors.name;
    final step = OnboardingStep.values.firstWhere(
      (s) => s.name == stepName,
      orElse: () => OnboardingStep.connectColors,
    );
    return OnboardingState(
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
      currentStep: step,
      completed: json['completed'] as bool? ?? false,
      skipped: json['skipped'] as bool? ?? false,
      tutorialVersion: json['tutorialVersion'] as int? ?? currentTutorialVersion,
    );
  }

  factory OnboardingState.defaults() {
    return const OnboardingState();
  }
}
