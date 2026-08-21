import 'package:flutter/material.dart';
import '../../game/tutorial/tutorial_manager.dart';
import 'tutorial_dialog.dart';

class TutorialOverlay extends StatelessWidget {
  final TutorialManager tutorialManager;
  final Widget child;

  const TutorialOverlay({
    super.key,
    required this.tutorialManager,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tutorialManager,
      builder: (context, _) {
        if (!tutorialManager.isActive) {
          return child;
        }

        final step = tutorialManager.currentStep;
        if (step == null) return child;

        return Stack(
          children: [
            child,
            // Dim background
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true, // We'll handle blocking in GameplayScreen via validator
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            // We could use CustomPaint to cut out a hole based on highlightType and targetId,
            // but for simplicity, we'll just overlay instructions and block unwanted taps
            // via the GameplayScreen.
            
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: SafeArea(
                child: TutorialDialog(
                  titleKey: step.titleKey,
                  descriptionKey: step.descriptionKey,
                ),
              ),
            ),
            
            if (step.requiredAction == 'continue')
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      tutorialManager.advanceStep();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
