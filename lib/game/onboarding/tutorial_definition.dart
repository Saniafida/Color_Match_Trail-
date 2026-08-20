import 'onboarding_step.dart';
import 'tutorial_event.dart';

/// Defines which gameplay event causes each tutorial step to advance.
class TutorialDefinition {
  final OnboardingStep step;
  final TutorialEvent triggerEvent;
  final int minMatchSize; // For matchCreated events, min blocks required

  const TutorialDefinition({
    required this.step,
    required this.triggerEvent,
    this.minMatchSize = 3,
  });

  static const List<TutorialDefinition> steps = [
    TutorialDefinition(
      step: OnboardingStep.connectColors,
      triggerEvent: TutorialEvent.matchCreated,
      minMatchSize: 3,
    ),
    TutorialDefinition(
      step: OnboardingStep.blast,
      triggerEvent: TutorialEvent.blastCompleted,
    ),
    TutorialDefinition(
      step: OnboardingStep.gravity,
      triggerEvent: TutorialEvent.blastCompleted,
    ),
    TutorialDefinition(
      step: OnboardingStep.largeMatch,
      triggerEvent: TutorialEvent.largeMatchCreated,
      minMatchSize: 5,
    ),
    TutorialDefinition(
      step: OnboardingStep.cascade,
      triggerEvent: TutorialEvent.cascadeCompleted,
    ),
    TutorialDefinition(
      step: OnboardingStep.goals,
      triggerEvent: TutorialEvent.goalUpdated,
    ),
    TutorialDefinition(
      step: OnboardingStep.moves,
      triggerEvent: TutorialEvent.matchCreated,
    ),
    TutorialDefinition(
      step: OnboardingStep.booster,
      triggerEvent: TutorialEvent.boosterUsed,
    ),
  ];
}
