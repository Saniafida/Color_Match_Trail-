import 'package:flutter/material.dart';
import 'pause_button.dart';

class LevelHeader extends StatelessWidget {
  final String levelId;
  final VoidCallback onPause;

  const LevelHeader({
    super.key,
    required this.levelId,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Level ${levelId.replaceAll(RegExp(r'[^0-9]'), '')}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        PauseButton(onPause: onPause),
      ],
    );
  }
}
