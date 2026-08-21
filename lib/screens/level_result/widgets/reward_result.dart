import 'package:flutter/material.dart';

class RewardResult extends StatelessWidget {
  final String rewardId;

  const RewardResult({super.key, required this.rewardId});

  @override
  Widget build(BuildContext context) {
    // In a real integration, we'd fetch the actual Reward details from RewardManager.
    // For now, we display a placeholder based on the ID.
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(25),
        border: Border.all(color: Colors.amber.withAlpha(128)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'REWARD UNLOCKED',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                'Reward: $rewardId', // Simplified for module
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
