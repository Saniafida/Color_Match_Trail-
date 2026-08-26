import 'package:flutter/material.dart';
import '../../../../game/boosters/booster_target_controller.dart';

class BoosterTargetOverlay extends StatelessWidget {
  final BoosterTargetController targetController;

  const BoosterTargetOverlay({super.key, required this.targetController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: targetController,
      builder: (context, child) {
        if (!targetController.isTargeting) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // 1. Subtle glowing ambient border to indicate targeting mode (IgnorePointer so board receives all taps)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Icon-only Cancel floating button (No text)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => targetController.cancel(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFC62828)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(color: Colors.white, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 26,
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
