import 'package:flutter/material.dart';
import '../../../../game/challenges/daily_challenge_definition.dart';
import '../../../../game/challenges/daily_challenge_progress.dart';
import '../../../../game/boosters/booster_definition.dart';
import '../../../../game/blocks/block_widget.dart';
import '../../../../models/models.dart';

class DailyChallengeCard extends StatelessWidget {
  final DailyChallengeDefinition challenge;
  final DailyChallengeProgress progress;
  final VoidCallback onClaim;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    required this.progress,
    required this.onClaim,
  });

  Widget _buildRewardIcon() {
    if (challenge.rewardId == 'coins') {
      return const Icon(Icons.monetization_on, color: Colors.amber, size: 28);
    } else {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == challenge.rewardId,
        orElse: () => BoosterType.hammer,
      );
      final def = BoosterDefinition.registry[type];
      return Icon(def?.icon ?? Icons.star, color: Colors.amber, size: 28);
    }
  }

  String _getRewardName() {
    if (challenge.rewardId == 'coins') {
      return "${challenge.rewardAmount} Coins";
    } else {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == challenge.rewardId,
        orElse: () => BoosterType.hammer,
      );
      final def = BoosterDefinition.registry[type];
      return "+${challenge.rewardAmount} ${def?.name ?? 'Booster'}";
    }
  }

  Widget _buildColorGoalItem(BlockColor color, int current, int target) {
    final double percent = (current / target).clamp(0.0, 1.0);
    final bool isDone = current >= target;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? Colors.greenAccent : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // 3D Block Image
          BlockWidget(
            block: Block(
              id: 'challenge_${color.name}',
              color: color,
              position: const Position(0, 0),
            ),
            size: 38,
          ),
          const SizedBox(width: 14),

          // Progress Info & Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${color.name.toUpperCase()} BLOCKS",
                      style: TextStyle(
                        color: isDone ? Colors.greenAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "$current / $target",
                      style: TextStyle(
                        color: isDone ? Colors.greenAccent : Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.greenAccent : Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Completion check
          if (isDone)
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canClaim = progress.completed && !progress.rewardClaimed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF241D17),
            Color(0xFF16110D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7A774).withValues(alpha: 0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "DAILY CHALLENGE",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (progress.completed)
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
            ],
          ),
          const SizedBox(height: 16),

          // Title / Objective
          const Text(
            "Collect 2 Color Blocks",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          // 2 Color Block Target Rows
          _buildColorGoalItem(
            challenge.primaryColor,
            progress.currentValue,
            challenge.primaryTarget,
          ),
          _buildColorGoalItem(
            challenge.secondaryColor,
            progress.currentValue2,
            challenge.secondaryTarget,
          ),
          const SizedBox(height: 16),

          // Reward Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                _buildRewardIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Reward: ${_getRewardName()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Claim Button
          ElevatedButton(
            onPressed: canClaim ? onClaim : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43B929),
              disabledBackgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Text(
              progress.rewardClaimed
                  ? "REWARD CLAIMED"
                  : (progress.completed ? "CLAIM REWARD" : "INCOMPLETE"),
              style: TextStyle(
                color: (progress.completed && !progress.rewardClaimed) ? Colors.white : Colors.white54,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

