import 'package:flutter/material.dart';

class ScoreBreakdown extends StatelessWidget {
  final int baseScore;
  final int bonusScore;

  const ScoreBreakdown({
    super.key,
    required this.baseScore,
    required this.bonusScore,
  });

  @override
  Widget build(BuildContext context) {
    if (bonusScore == 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Base: $baseScore',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Text(
          '+ Bonus: $bonusScore',
          style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
