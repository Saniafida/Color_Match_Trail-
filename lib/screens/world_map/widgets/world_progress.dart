import 'package:flutter/material.dart';
import '../../../game/progression/world_progress.dart';

class WorldProgressWidget extends StatelessWidget {
  final WorldProgress progress;

  const WorldProgressWidget({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = progress.completionPercentage;
    final isComplete = progress.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(180),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete ? '🎉 World Completed!' : 'World Progress',
                style: TextStyle(
                  color: isComplete ? const Color(0xFFFFD700) : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${progress.completedLevels}/${progress.totalLevels} Levels (${(percentage * 100).toInt()}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFF4CAF50) : const Color(0xFF38BDF8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
