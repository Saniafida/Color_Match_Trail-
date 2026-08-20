import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../game/progression/progression_manager.dart';
import '../../core/data/game_data_manager.dart';
import 'widgets/world_card.dart';
import 'widgets/level_node.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  late final ProgressionManager _progressionManager;
  late final GameDataManager _dataManager;

  @override
  void initState() {
    super.initState();
    _progressionManager = ServiceLocator.instance.progressionManager;
    _dataManager = ServiceLocator.instance.gameDataManager;
    _progressionManager.addListener(_onProgressionUpdated);
  }

  @override
  void dispose() {
    _progressionManager.removeListener(_onProgressionUpdated);
    super.dispose();
  }

  void _onProgressionUpdated() {
    setState(() {});
  }

  void _playLevel(String levelId) {
    _progressionManager.setCurrentLevel(levelId);
    // In a real app, this pushes the gameplay screen.
    // e.g., Navigator.pushNamed(context, '/gameplay', arguments: levelId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting $levelId... (Offline)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worlds = _dataManager.getAllWorlds();
    final state = _progressionManager.state;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('World Map'),
        backgroundColor: Colors.indigo.shade900,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                '⭐ ${_progressionManager.getWorldProgress(worlds.isNotEmpty ? worlds.first.worldId : "").totalStars > 0 ? _progressionManager.getWorldProgress(worlds.isNotEmpty ? worlds.first.worldId : "").earnedStars : 0}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: worlds.length,
        itemBuilder: (context, index) {
          final world = worlds[index];
          final worldProgress = _progressionManager.getWorldProgress(world.worldId);

          return Column(
            children: [
              WorldCard(world: world, progress: worldProgress),
              if (worldProgress.unlocked)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: world.levelIds.map((levelId) {
                      final levelProgress = state.levels[levelId];
                      if (levelProgress == null) return const SizedBox.shrink();

                      return LevelNode(
                        progress: levelProgress,
                        isCurrent: state.currentLevel == levelId,
                        onTap: () => _playLevel(levelId),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
