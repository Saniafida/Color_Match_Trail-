import 'package:flutter/material.dart';
import '../../../game/achievements/achievement_definition.dart';
import '../../../game/achievements/achievement_progress.dart';

class AchievementCard extends StatelessWidget {
  final AchievementDefinition definition;
  final AchievementProgress progress;

  const AchievementCard({
    super.key,
    required this.definition,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = progress.completed;
    final bool isHidden = false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF1B2735) : const Color(0xFF141E2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? Colors.amber.withAlpha(100) : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(isUnlocked, isHidden),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHidden ? '???' : definition.titleKey,
                  style: TextStyle(
                    color: isUnlocked ? Colors.amber : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHidden ? 'Keep playing to discover this achievement' : definition.descriptionKey,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                if (!isUnlocked && !isHidden) _buildProgressBar(),
                if (isUnlocked) _buildRewardClaimedLabel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(bool isUnlocked, bool isHidden) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.amber.withAlpha(30) : Colors.black26,
        shape: BoxShape.circle,
        border: Border.all(
          color: isUnlocked ? Colors.amber : Colors.white24,
          width: 2,
        ),
      ),
      child: Center(
        child: isHidden
            ? const Icon(Icons.help_outline, color: Colors.white54)
            : isUnlocked
                ? const Icon(Icons.emoji_events, color: Colors.amber)
                : const Icon(Icons.lock, color: Colors.white54, size: 20),
      ),
    );
  }

  Widget _buildProgressBar() {
    final double percent = (progress.currentValue / progress.targetValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${progress.currentValue} / ${progress.targetValue}',
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: Colors.black26,
          color: Colors.amber,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildRewardClaimedLabel() {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
        const SizedBox(width: 4),
        Text(
          progress.rewardGranted ? 'Reward Granted' : 'Unlocked',
          style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
        ),
      ],
    );
  }
}
