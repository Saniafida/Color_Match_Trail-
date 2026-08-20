import 'package:flutter/material.dart';

class HomeProgress extends StatelessWidget {
  final int highestUnlockedLevel;
  final int totalStars;
  final int totalLevels;

  const HomeProgress({
    super.key,
    required this.highestUnlockedLevel,
    required this.totalStars,
    required this.totalLevels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'LEVEL $highestUnlockedLevel',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(
                totalStars.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.map, color: Colors.white70, size: 20),
              const SizedBox(width: 4),
              Text(
                '$highestUnlockedLevel / $totalLevels',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
