import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import 'widgets/statistics_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final stats = ServiceLocator.instance.statisticsManager.stats;

    return Scaffold(
      backgroundColor: const Color(0xFF141E2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PLAYER STATISTICS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          StatisticsCard(
            title: 'Levels Completed',
            value: '${stats.levelsCompleted}',
            icon: Icons.flag,
            color: Colors.greenAccent,
          ),
          StatisticsCard(
            title: 'Stars Earned',
            value: '${stats.totalStars}',
            icon: Icons.star,
            color: Colors.amber,
          ),
          StatisticsCard(
            title: 'Highest Score',
            value: '${stats.highestScore}',
            icon: Icons.emoji_events,
            color: Colors.purpleAccent,
          ),
          StatisticsCard(
            title: 'Best Combo',
            value: '${stats.highestCombo}',
            icon: Icons.bolt,
            color: Colors.cyanAccent,
          ),
          StatisticsCard(
            title: 'Blocks Cleared',
            value: '${stats.totalBlocksCleared}',
            icon: Icons.grid_view,
            color: Colors.blueAccent,
          ),
          StatisticsCard(
            title: 'Boosters Used',
            value: '${stats.totalBoostersUsed}',
            icon: Icons.rocket_launch,
            color: Colors.orangeAccent,
          ),
          StatisticsCard(
            title: 'Play Time',
            value: _formatDuration(stats.totalPlayTime),
            icon: Icons.timer,
            color: Colors.pinkAccent,
          ),
        ],
      ),
    );
  }
}
