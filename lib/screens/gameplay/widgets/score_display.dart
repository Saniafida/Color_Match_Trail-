import 'package:flutter/material.dart';
import '../../../game/score/score_controller.dart';

class ScoreDisplay extends StatelessWidget {
  final ScoreController scoreController;

  const ScoreDisplay({
    super.key,
    required this.scoreController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scoreController,
      builder: (context, child) {
        final state = scoreController.state;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'SCORE',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${state.currentScore}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
