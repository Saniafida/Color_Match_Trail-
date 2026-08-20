import 'package:flutter/material.dart';
import '../../../game/combo/combo_controller.dart';

class ComboDisplay extends StatelessWidget {
  final ComboController comboController;

  const ComboDisplay({
    super.key,
    required this.comboController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: comboController,
      builder: (context, child) {
        final state = comboController.state;
        if (state.multiplier <= 1.0) {
          return const SizedBox.shrink(); // No combo
        }

        return IgnorePointer(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(state.level),
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: (1.0 - (1.0 - scale).abs()).clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))
                      ],
                    ),
                    child: Text(
                      'COMBO x${state.multiplier.toInt()}!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
