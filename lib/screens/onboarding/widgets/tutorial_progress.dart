import 'package:flutter/material.dart';
import '../../../game/onboarding/onboarding_step.dart';

class TutorialProgress extends StatelessWidget {
  final OnboardingStep currentStep;

  const TutorialProgress({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    // Exclude 'complete' from dots
    final steps = OnboardingStep.values
        .where((s) => s != OnboardingStep.complete)
        .toList();
    final currentIndex = steps.indexOf(currentStep);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        final isActive = i == currentIndex;
        final isDone = i < currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone
                ? Colors.amber.withAlpha(150)
                : isActive
                    ? Colors.amber
                    : Colors.white30,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
