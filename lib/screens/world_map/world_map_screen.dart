import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../game/progression/progression_manager.dart';
import '../../game/progression/level_progress.dart';
import '../../core/data/game_data_manager.dart';
import '../../game/settings/settings_manager.dart';
import 'widgets/world_header.dart';
import 'widgets/world_progress.dart';
import 'widgets/world_navigation.dart';
import 'widgets/level_node.dart';
import 'widgets/level_path.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  late final ProgressionManager _progressionManager;
  late final GameDataManager _dataManager;
  late final SettingsManager _settingsManager;

  int _selectedWorldIndex = 0;

  @override
  void initState() {
    super.initState();
    _progressionManager = ServiceLocator.instance.progressionManager;
    _dataManager = ServiceLocator.instance.gameDataManager;
    _settingsManager = ServiceLocator.instance.settingsManager;

    _progressionManager.addListener(_onProgressionUpdated);

    // Default to the world containing the current playable level
    _findInitialWorld();
  }

  void _findInitialWorld() {
    final currentLevelId = _progressionManager.currentPlayableLevel;
    final worlds = _dataManager.getAllWorlds();
    for (int i = 0; i < worlds.length; i++) {
      if (worlds[i].levelIds.contains(currentLevelId)) {
        _selectedWorldIndex = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _progressionManager.removeListener(_onProgressionUpdated);
    super.dispose();
  }

  void _onProgressionUpdated() {
    if (mounted) setState(() {});
  }

  void _onNodeTapped(String levelId, LevelProgress progress) {
    final validation = _progressionManager.validateLevelAccess(levelId);

    if (!validation.isUnlocked) {
      _showLockedDialog(validation.message ?? 'This level is locked.');
      return;
    }

    _showLevelPreviewSheet(levelId, progress);
  }

  void _showLockedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Color(0xFFFF9800)),
            SizedBox(width: 8),
            Text('Level Locked', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  void _showLevelPreviewSheet(String levelId, LevelProgress progress) {
    final levelNumber = levelId.replaceAll(RegExp(r'[^0-9]'), '');
    final levelData = _dataManager.getLevel(levelId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Level $levelNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final earned = index < progress.bestStars;
                    return Icon(
                      Icons.star_rounded,
                      size: 28,
                      color: earned ? const Color(0xFFFFD700) : Colors.white24,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (progress.completed) ...[
                  Text(
                    'Best Score: ${progress.bestScore}',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                ],
                if (levelData != null) ...[
                  Text(
                    'Moves: ${levelData.moveLimit}  •  Target: ${levelData.scoreTarget}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _playLevel(levelId);
                    },
                    child: Text(
                      progress.completed ? 'Replay Level' : 'Play Level',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playLevel(String levelId) {
    _progressionManager.setCurrentLevel(levelId);
    Navigator.pushNamed(context, AppRoutes.gameplay, arguments: levelId);
  }

  @override
  Widget build(BuildContext context) {
    final worlds = _dataManager.getAllWorlds();
    final state = _progressionManager.state;
    final totalCampaignStars = _progressionManager.totalStars;
    final reducedMotion = _settingsManager.state.reducedEffects;

    if (worlds.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: Text('No worlds available', style: TextStyle(color: Colors.white))),
      );
    }

    final currentWorld = worlds[_selectedWorldIndex.clamp(0, worlds.length - 1)];
    final worldProgress = _progressionManager.getWorldProgress(currentWorld.worldId);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('World Map', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Level Select Grid shortcut
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Level Select',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.levelSelect);
            },
          ),
          // Total Stars badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700).withAlpha(120)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$totalCampaignStars',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getWorldGradient(currentWorld.worldId),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. World Navigation Selector
              WorldNavigation(
                worlds: worlds,
                selectedIndex: _selectedWorldIndex,
                onWorldSelected: (idx) {
                  final targetWorld = worlds[idx];
                  final check = _progressionManager.validateWorldAccess(targetWorld.worldId);
                  if (!check.isUnlocked) {
                    _showLockedDialog(check.message ?? 'This world is locked.');
                  } else {
                    setState(() {
                      _selectedWorldIndex = idx;
                    });
                  }
                },
                getWorldProgress: (id) => _progressionManager.getWorldProgress(id),
              ),

              // 2. World Header Info
              WorldHeader(
                world: currentWorld,
                progress: worldProgress,
                totalCampaignStars: totalCampaignStars,
              ),

              // 3. World Progress Bar
              WorldProgressWidget(progress: worldProgress),

              const SizedBox(height: 8),

              // 4. Interactive Level Map Trail
              Expanded(
                child: _buildTrailMap(currentWorld.levelIds, state, reducedMotion),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailMap(List<String> levelIds, dynamic state, bool reducedMotion) {
    if (levelIds.isEmpty) {
      return const Center(child: Text('No levels in this world', style: TextStyle(color: Colors.white70)));
    }

    final double nodeHeight = 110.0;
    final int count = levelIds.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double totalHeight = count * nodeHeight + 80;

        // Calculate zigzag offsets for each node
        final List<Offset> positions = [];
        final List<bool> unlockedStates = [];

        for (int i = 0; i < count; i++) {
          final levelId = levelIds[i];
          final progress = state.levels[levelId] ?? LevelProgress.locked(levelId);
          unlockedStates.add(progress.unlocked);

          // Alternating X positions: center, left, center, right...
          double xOffset;
          if (i % 4 == 0) {
            xOffset = width * 0.5;
          } else if (i % 4 == 1) {
            xOffset = width * 0.25;
          } else if (i % 4 == 2) {
            xOffset = width * 0.5;
          } else {
            xOffset = width * 0.75;
          }

          final yOffset = 40 + i * nodeHeight + 38; // center of node
          positions.add(Offset(xOffset, yOffset));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: SizedBox(
            height: totalHeight,
            width: width,
            child: Stack(
              children: [
                // 1. Trail Path
                CustomPaint(
                  size: Size(width, totalHeight),
                  painter: LevelPathPainter(
                    nodePositions: positions,
                    nodeUnlocked: unlockedStates,
                  ),
                ),

                // 2. Level Nodes
                for (int i = 0; i < count; i++) ...[
                  Positioned(
                    left: positions[i].dx - 38,
                    top: positions[i].dy - 38,
                    child: Builder(
                      builder: (context) {
                        final levelId = levelIds[i];
                        final progress = state.levels[levelId] ?? (i == 0 ? LevelProgress.unlocked(levelId) : LevelProgress.locked(levelId));
                        final isCurrent = state.currentLevel == levelId || _progressionManager.currentPlayableLevel == levelId;

                        return LevelNode(
                          progress: progress,
                          isCurrent: isCurrent,
                          reducedMotion: reducedMotion,
                          onTap: () => _onNodeTapped(levelId, progress),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getWorldGradient(String worldId) {
    if (worldId.contains('2')) {
      return const [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF020617)];
    }
    return const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF020617)];
  }
}
