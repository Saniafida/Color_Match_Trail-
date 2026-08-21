import 'package:flutter/material.dart';

class ResultHeader extends StatelessWidget {
  final bool isWon;

  const ResultHeader({super.key, required this.isWon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          isWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
          size: 64,
          color: isWon ? Colors.amber : Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          isWon ? 'Level Complete!' : 'Level Failed',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isWon ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
      ],
    );
  }
}
