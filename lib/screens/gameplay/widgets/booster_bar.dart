import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
import '../../../game/tutorial/tutorial_validator.dart';
import '../../../game/boosters/booster_manager.dart';
import '../../../models/models.dart';

class BoosterBar extends StatelessWidget {
  final BoosterManager boosterManager;

  const BoosterBar({
    super.key,
    required this.boosterManager,
  });

  String _getBoosterAsset(BoosterType type) {
    switch (type) {
      case BoosterType.hammer:
        return 'assets/images/boosters/hammer.png';
      case BoosterType.rowClear:
        return 'assets/images/power_ups/powerup_4_rocket.png';
      case BoosterType.areaBlast:
        return 'assets/images/power_ups/powerup_5_bomb.png';
      case BoosterType.colorClear:
        return 'assets/images/power_ups/powerup_7_color_bomb.png';
      case BoosterType.shuffle:
        return 'assets/images/boosters/shuffle.png';
      case BoosterType.extraMoves:
        return 'assets/images/boosters/extra_moves.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: boosterManager,
      builder: (context, child) {
        // Display all 6 booster power-ups
        const displayTypes = [
          BoosterType.hammer,
          BoosterType.rowClear,
          BoosterType.areaBlast,
          BoosterType.colorClear,
          BoosterType.shuffle,
          BoosterType.extraMoves,
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3E200C).withAlpha(220),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(
              top: BorderSide(color: Color(0xFFFFD54F), width: 2.5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                offset: Offset(0, -3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayTypes.map((type) {
              final isSelected = boosterManager.selectedBoosterDef?.type == type ||
                  boosterManager.secondBoosterDef?.type == type;
              final count = boosterManager.inventory.getQuantity(type);
              final isAvailable = boosterManager.canActivateBooster(type) || isSelected;

              return _buildBoosterButton(type, isSelected, isAvailable, count);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBoosterButton(BoosterType type, bool isSelected, bool isAvailable, int count) {
    final assetPath = _getBoosterAsset(type);

    return GestureDetector(
      onTap: isAvailable
          ? () {
              final tutorialManager = ServiceLocator.instance.tutorialManager;
              if (!TutorialValidator.canUseBooster(tutorialManager, type)) return;

              boosterManager.selectBooster(type);

              if (tutorialManager.isActive) {
                final step = tutorialManager.currentStep;
                if (step != null && step.requiredAction == 'use_booster' && step.targetId == type.name) {
                  tutorialManager.advanceStep();
                }
              }
            }
          : null,
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Glowing golden aura when selected
            if (isSelected)
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.85),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

            // Wooden / Gold Circular Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFFEE58), Color(0xFFFFB300)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF8D582A), Color(0xFF5D3512)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFFFFD54F),
                  width: isSelected ? 2.5 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.7) : Colors.black45,
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.5),
                child: ClipOval(
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // Count Badge (Red / Coral Pill)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Text(
                count > 0 ? '$count' : '0',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
