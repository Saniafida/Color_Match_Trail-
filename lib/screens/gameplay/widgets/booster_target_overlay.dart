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

        final booster = targetController.currentBooster;
        
        return Stack(
          children: [
            // Darken background slightly to indicate mode
            Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
            
            // Instruction Text
            Positioned(
              top: 150, // Below HUD
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Text(
                    "Select Target for ${booster?.name ?? 'Booster'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Cancel Button
            Positioned(
              bottom: 120, // Above Booster Bar
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => targetController.cancel(),
                  icon: const Icon(Icons.close),
                  label: const Text("CANCEL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),
            ),

            // Gesture interceptor for the board
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  // In a real grid, we'd translate global position to board Position.
                  // Since the BoardWidget already translates taps, it's easier to let the BoardWidget intercept if we want precise Row/Col.
                  // Wait, the BoardWidget handles drag, not tap.
                  // For the sake of this module, we will just let TrailController ignore inputs when targeting is active,
                  // and we will modify BoardWidget to emit onTapDown if targeting.
                  // Alternatively, we can just wrap the BoardWidget in GameplayScreen.
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
