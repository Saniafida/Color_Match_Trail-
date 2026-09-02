import 'package:flutter/material.dart';
import '../../../game/score/score_controller.dart';

class ScoreDisplay extends StatelessWidget {
  final ScoreController scoreController;
  final List<int> starThresholds;

  const ScoreDisplay({
    super.key,
    required this.scoreController,
    this.starThresholds = const [1000, 2000, 3000],
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scoreController,
      builder: (context, child) {
        final state = scoreController.state;
        final score = state.currentScore;

        int stars = 0;
        if (starThresholds.isNotEmpty && score >= starThresholds[0]) stars = 1;
        if (starThresholds.length > 1 && score >= starThresholds[1]) stars = 2;
        if (starThresholds.length > 2 && score >= starThresholds[2]) stars = 3;

        return Container(
          width: 65,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6B3A18),
                Color(0xFF45220A),
                Color(0xFF2B1304),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFD54F),
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
                // "Score" title
                const Text(
                  'Score',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 1.5),
                    ],
                  ),
                ),

                const SizedBox(height: 1),

                // Score number
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                    ],
                  ),
                ),

                const SizedBox(height: 1.5),

                // 3 Stars below score
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStar(stars >= 1),
                    const SizedBox(width: 1.5),
                    _buildStar(stars >= 2),
                    const SizedBox(width: 1.5),
                    _buildStar(stars >= 3),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStar(bool isFilled) {
    return Icon(
      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
      color: isFilled ? const Color(0xFFFFD54F) : const Color(0xFFFFD54F).withValues(alpha: 0.55),
      size: 11,
    );
  }
}
