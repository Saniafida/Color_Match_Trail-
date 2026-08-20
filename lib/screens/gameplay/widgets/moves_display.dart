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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLow 
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: isLow ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Column(
            children: [
              const Text(
                'MOVES',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${state.remainingMoves}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isLow ? Colors.redAccent : Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
