import 'package:flutter/material.dart';
import '../../../game/profile/player_statistics.dart';

class ProfileStatsCard extends StatelessWidget {
  final PlayerStatistics stats;

  const ProfileStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lifetime Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _StatItem(label: 'Games Played', value: '${stats.gamesPlayed}'),
        _StatItem(label: 'Games Won', value: '${stats.gamesWon}'),
        _StatItem(label: 'Total Stars', value: '${stats.totalStars}'),
        _StatItem(label: 'High Score', value: '${stats.totalScore}'),
        _StatItem(label: 'Max Combo', value: '${stats.highestCombo}'),
        _StatItem(label: 'Boosters Used', value: '${stats.boostersUsed}'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
