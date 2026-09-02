import 'package:flutter/material.dart';
import '../../../game/moves/move_controller.dart';

class MovesDisplay extends StatelessWidget {
  final MoveController moveController;

  const MovesDisplay({
    super.key,
    required this.moveController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: moveController,
      builder: (context, child) {
        final state = moveController.state;
        final isLow = state.remainingMoves <= 5;

        return Container(
          width: 58,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLow
                  ? const [Color(0xFF7A1C1C), Color(0xFF4D0A0A), Color(0xFF330505)]
                  : const [Color(0xFF6B3A18), Color(0xFF45220A), Color(0xFF2B1304)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLow ? const Color(0xFFFF5252) : const Color(0xFFFFD54F),
              width: 1.6,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1E0C02),
                offset: Offset(0, 2.5),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 3),
                blurRadius: 4,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Moves',
                  style: TextStyle(
                    color: isLow ? const Color(0xFFFF8A80) : const Color(0xFFFFD54F),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 1.5),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${state.remainingMoves}',
                  style: TextStyle(
                    color: isLow ? const Color(0xFFFF5252) : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
