import 'package:flutter/material.dart';

class ScoreResult extends StatelessWidget {
  final int score;

  const ScoreResult({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'SCORE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Text(
          score.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
