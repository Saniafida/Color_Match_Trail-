import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
import '../../../game/tutorial/tutorial_validator.dart';
import '../../../game/boosters/booster_manager.dart';
import '../../../game/boosters/booster_definition.dart';
import '../../../models/models.dart';

class BoosterBar extends StatelessWidget {
  final BoosterManager boosterManager;

  const BoosterBar({
    super.key,
    required this.boosterManager,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: boosterManager,
      builder: (context, child) {
        final availableBoosters = BoosterType.values;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: availableBoosters.map((type) {
              final isSelected = boosterManager.selectedBoosterDef?.type == type ||
                                 boosterManager.secondBoosterDef?.type == type;
              final count = boosterManager.inventory.getQuantity(type);
              
              // It's available if we can activate it, or if it's already selected
              final isAvailable = boosterManager.canActivateBooster(type) || isSelected;
              
              return _buildBoosterIcon(type, isSelected, isAvailable, count);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBoosterIcon(BoosterType type, bool isSelected, bool isAvailable, int count) {
    final def = BoosterDefinition.registry[type]!;

    return GestureDetector(
      onTap: isAvailable ? () {
        final tutorialManager = ServiceLocator.instance.tutorialManager;
        if (!TutorialValidator.canUseBooster(tutorialManager, type)) return;
        
        boosterManager.selectBooster(type);

        if (tutorialManager.isActive) {
          final step = tutorialManager.currentStep;
          if (step != null && step.requiredAction == 'use_booster' && step.targetId == type.name) {
            tutorialManager.advanceStep();
          }
        }
      } : null,
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.4,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber.withValues(alpha: 0.3) : Colors.white24,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.amber : Colors.white54,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(def.icon, color: isAvailable ? Colors.white : Colors.grey, size: 24),
              if (count > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
