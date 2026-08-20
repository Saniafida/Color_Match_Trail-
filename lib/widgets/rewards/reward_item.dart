import 'package:flutter/material.dart';
import '../../game/boosters/booster_definition.dart';
import '../../models/booster.dart';
import '../../game/rewards/reward_definition.dart';

class RewardItemWidget extends StatelessWidget {
  final RewardDefinition reward;

  const RewardItemWidget({super.key, required this.reward});

  Widget _buildIcon() {
    if (reward.type == RewardType.coins) {
      return const Icon(Icons.monetization_on, color: Colors.amber, size: 40);
    } else if (reward.type == RewardType.booster && reward.itemId != null) {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == reward.itemId,
        orElse: () => BoosterType.hammer,
      );
      final def = BoosterDefinition.registry[type];
      return Icon(def?.icon ?? Icons.star, color: Colors.amber, size: 40);
    }
    return const Icon(Icons.star, color: Colors.amber, size: 40);
  }

  String _getName() {
    if (reward.type == RewardType.coins) return 'Coins';
    if (reward.type == RewardType.booster && reward.itemId != null) {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == reward.itemId,
        orElse: () => BoosterType.hammer,
      );
      return BoosterDefinition.registry[type]?.name ?? 'Booster';
    }
    if (reward.type == RewardType.extraMoves) return 'Extra Moves';
    return 'Reward';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber.withAlpha(128), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.amber.withAlpha(51), blurRadius: 10, spreadRadius: 2),
            ]
          ),
          child: _buildIcon(),
        ),
        const SizedBox(height: 12),
        Text(
          '+\${reward.amount}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getName(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
