import 'package:flutter/material.dart';
import '../../../../game/challenges/daily_challenge_definition.dart';
import '../../../../game/challenges/daily_challenge_progress.dart';
import '../../../../game/challenges/daily_challenge_type.dart';
import '../../../../game/boosters/booster_definition.dart';
import '../../../../models/booster.dart';

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

  String _getObjectiveText() {
    switch (challenge.challengeType) {
      case DailyChallengeType.score:
        return "Score ${challenge.target} points";
      case DailyChallengeType.clearBlocks:
        return "Clear ${challenge.target} blocks";
      case DailyChallengeType.createSpecial:
        return "Create ${challenge.target} Special Blocks";
      case DailyChallengeType.cascade:
        return "Trigger ${challenge.target} Cascades";
      case DailyChallengeType.combo:
        return "Reach a Combo of ${challenge.target}";
      case DailyChallengeType.completeLevel:
        return "Complete 1 Level";
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final double percent = (progress.currentValue / challenge.target).clamp(0.0, 1.0);
    final bool canClaim = progress.completed && !progress.rewardClaimed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C3E50),
            const Color(0xFF1A2533),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              const Text(
                "DAILY CHALLENGE",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (progress.completed)
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          
          // Objective
          Text(
            _getObjectiveText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 12,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress.completed ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${progress.currentValue} / ${challenge.target}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Reward Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 24),
          
          // Claim Button
          ElevatedButton(
            onPressed: canClaim ? onClaim : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              progress.rewardClaimed ? "REWARD CLAIMED" : (progress.completed ? "CLAIM REWARD" : "INCOMPLETE"),
              style: TextStyle(
                color: (progress.completed && !progress.rewardClaimed) ? Colors.white : Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
