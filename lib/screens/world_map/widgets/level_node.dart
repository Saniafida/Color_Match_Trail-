import 'package:flutter/material.dart';
import '../../../game/progression/level_progress.dart';

class LevelNode extends StatelessWidget {
  final LevelProgress progress;
  final bool isCurrent;
  final VoidCallback onTap;

  const LevelNode({
    super.key,
    required this.progress,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: progress.unlocked ? onTap : null,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: progress.unlocked ? (isCurrent ? Colors.blueAccent : Colors.blue) : Colors.grey,
          border: Border.all(
            color: isCurrent ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!progress.unlocked)
              const Icon(Icons.lock, color: Colors.white54)
            else ...[
              Text(
                progress.levelId.replaceAll(RegExp(r'[^0-9]'), ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              if (progress.completed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Icon(
                      Icons.star,
                      size: 14,
                      color: index < progress.stars ? Colors.yellow : Colors.black12,
                    );
                  }),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
