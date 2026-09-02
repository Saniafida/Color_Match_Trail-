import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
import '../../../game/tutorial/tutorial_validator.dart';
import '../../../game/boosters/booster_manager.dart';
import '../../../game/level_result/level_result_controller.dart';
import '../../../game/blast/blast_controller.dart';
import '../../../models/models.dart';

class BoosterBar extends StatelessWidget {
  final BoosterManager boosterManager;
  final LevelResultController? levelResultController;
  final BlastController? blastController;

  const BoosterBar({
    super.key,
    required this.boosterManager,
    this.levelResultController,
    this.blastController,
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
    final listenables = <Listenable>[
      boosterManager,
      if (levelResultController != null) levelResultController!,
      if (blastController != null) blastController!,
    ];

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, child) {
        const displayTypes = [
          BoosterType.hammer,
          BoosterType.rowClear,
          BoosterType.areaBlast,
          BoosterType.colorClear,
          BoosterType.shuffle,
          BoosterType.extraMoves,
        ];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7A431D),
                Color(0xFF53280B),
                Color(0xFF381705),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFFFD54F),
              width: 2.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1E0C02),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0, 6),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayTypes.map((type) {
              final isSelected = boosterManager.selectedBoosterDef?.type == type ||
                  boosterManager.secondBoosterDef?.type == type;
              final count = boosterManager.inventory.getQuantity(type);
              final isAvailable = (count > 0 && boosterManager.canActivateBooster(type)) || isSelected;

              return _buildBoosterSlot(type, isSelected, isAvailable, count);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBoosterSlot(BoosterType type, bool isSelected, bool isAvailable, int count) {
    final assetPath = _getBoosterAsset(type);
    const double slotSize = 48.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
        scale: isSelected ? 1.14 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: isAvailable ? 1.0 : 0.65,
          duration: const Duration(milliseconds: 180),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Golden Glow Aura when selected
              if (isSelected)
                Container(
                  width: slotSize + 10,
                  height: slotSize + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.9),
                        blurRadius: 14,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),

              // Circular Slot Container
              Container(
                width: slotSize,
                height: slotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFEE58), Color(0xFFFFB300)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : (type == BoosterType.extraMoves
                          ? const LinearGradient(
                              colors: [Color(0xFF29B6F6), Color(0xFF0288D1), Color(0xFF01579B)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF5D3312), Color(0xFF3E1F08), Color(0xFF261203)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : (type == BoosterType.extraMoves ? const Color(0xFFB3E5FC) : const Color(0xFFFFD54F)),
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
                  padding: const EdgeInsets.all(5.0),
                  child: type == BoosterType.extraMoves
                      ? const Center(
                          child: Text(
                            '+5',
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF01579B),
                                  offset: Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                        ),
                ),
              ),

              // Red Circular Count Badge on Bottom Right
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFD32F2F), Color(0xFFB71C1C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(color: Colors.white, width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        offset: Offset(0, 1.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      count > 0 ? '$count' : '0',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
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
