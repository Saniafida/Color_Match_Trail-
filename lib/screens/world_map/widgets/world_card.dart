import 'package:flutter/material.dart';
import '../../../models/data/world_definition.dart';
import '../../../game/progression/world_progress.dart';

class WorldCard extends StatelessWidget {
  final WorldDefinition world;
  final WorldProgress progress;

  const WorldCard({
    super.key,
    required this.world,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: progress.unlocked ? Colors.indigo.shade800 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                world.titleKey,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!progress.unlocked)
                const Icon(Icons.lock, color: Colors.white54, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            world.descriptionKey,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          if (progress.unlocked)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${progress.earnedStars} / ${progress.totalStars}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${(progress.completionPercentage * 100).toInt()}% Complete',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            )
          else
            Text(
              'Requires ${world.unlockRequirement} Stars to Unlock',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
