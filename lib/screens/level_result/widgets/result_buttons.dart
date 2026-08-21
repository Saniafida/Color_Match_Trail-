import 'package:flutter/material.dart';
import '../../../../widgets/buttons/game_button.dart';

class ResultButtons extends StatelessWidget {
  final bool isWon;
  final VoidCallback onRetry;
  final VoidCallback? onNextLevel;
  final VoidCallback onMap;

  const ResultButtons({
    super.key,
    required this.isWon,
    required this.onRetry,
    this.onNextLevel,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isWon && onNextLevel != null)
          GameButton(
            text: 'Next Level',
            onPressed: onNextLevel!,
          ),
        if (!isWon)
          GameButton(
            text: 'Retry',
            onPressed: onRetry,
          ),
        const SizedBox(height: 16),
        GameButton(
          text: 'Return to Map',
          onPressed: onMap,
        ),
      ],
    );
  }
}
