import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../game/progression/progression_manager.dart';
import '../../game/progression/level_progress.dart';
import '../../core/data/game_data_manager.dart';
import '../../widgets/common/game_top_bar.dart';
import '../../widgets/common/wood_sign_header.dart';
import '../../widgets/buttons/glossy_button.dart';
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

  int _selectedWorldIndex = 0;

  @override
  void initState() {
    super.initState();
    _progressionManager = ServiceLocator.instance.progressionManager;
    _dataManager = ServiceLocator.instance.gameDataManager;

    _progressionManager.addListener(_onProgressionUpdated);
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
        backgroundColor: const Color(0xFF5D3A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 2.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Color(0xFFFFD54F)),
            SizedBox(width: 8),
            Text('Level Locked', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFFFF9EC), fontSize: 16),
        ),
        actions: [
          GlossyButton(
            text: 'OK',
            color: GlossyButtonColor.green,
            height: 44,
            fontSize: 16,
            onPressed: () => Navigator.pop(context),
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
            color: Color(0xFF5D3A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFFFFD54F), width: 3),
              left: BorderSide(color: Color(0xFFFFD54F), width: 3),
              right: BorderSide(color: Color(0xFFFFD54F), width: 3),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Level $levelNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.black, offset: Offset(1, 2), blurRadius: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final earned = index < progress.bestStars;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Image.asset(
                        'assets/images/icons/icon_star_gold.png',
                        width: 32,
                        height: 32,
                        color: earned ? null : Colors.black45,
                        colorBlendMode: earned ? null : BlendMode.srcATop,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (progress.completed) ...[
                  Text(
                    'Best Score: ${progress.bestScore}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (levelData != null) ...[
                  Text(
                    'Moves: ${levelData.moveLimit}  •  Target: ${levelData.scoreTarget}',
                    style: const TextStyle(color: Color(0xFFFFF9EC), fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                ],
                GlossyButton(
                  text: progress.completed ? 'Replay Level' : 'Play Level',
                  color: GlossyButtonColor.green,
                  height: 54,
                  fontSize: 20,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    _playLevel(levelId);
                  },
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

    if (worlds.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No worlds available')),
      );
    }

    final currentWorld = worlds[_selectedWorldIndex.clamp(0, worlds.length - 1)];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Illustrated Map Background
          Image.asset(
            'assets/images/backgrounds/bg_world_map.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Status Bar (Hearts, Coins, Gems, Settings)
                const GameTopBar(
                  showProfile: false,
                  showSettings: true,
                ),

                // Wood Sign Header: "World Map"
                WoodSignHeader(
                  title: 'World Map',
                  onBack: () => Navigator.pop(context),
                ),

                // Interactive Level Nodes Map Trail
                Expanded(
                  child: _buildTrailMap(currentWorld.levelIds, state),
                ),

                // Bottom World Selector Tabs ("World 1", "World 2 🔒", "World 3 🔒")
                _buildBottomWorldTabs(worlds),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailMap(List<String> levelIds, dynamic state) {
    if (levelIds.isEmpty) {
      return const Center(
        child: Text('No levels in this world', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }

    final double nodeHeight = 90.0;
    final int count = levelIds.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double totalHeight = count * nodeHeight + 60;

        final List<Offset> positions = [];
        final List<bool> unlockedStates = [];

        for (int i = 0; i < count; i++) {
          final levelId = levelIds[i];
          final progress = state.levels[levelId] ?? (i == 0 ? LevelProgress.unlocked(levelId) : LevelProgress.locked(levelId));
          unlockedStates.add(progress.unlocked);

          // S-curve winding positions
          double xOffset;
          if (i % 4 == 0) {
            xOffset = width * 0.5;
          } else if (i % 4 == 1) {
            xOffset = width * 0.28;
          } else if (i % 4 == 2) {
            xOffset = width * 0.5;
          } else {
            xOffset = width * 0.72;
          }

          final yOffset = 30 + i * nodeHeight + 36;
          positions.add(Offset(xOffset, yOffset));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: SizedBox(
            height: totalHeight,
            width: width,
            child: Stack(
              children: [
                // 1. Path Line
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
                    left: positions[i].dx - 36,
                    top: positions[i].dy - 36,
                    child: Builder(
                      builder: (context) {
                        final levelId = levelIds[i];
                        final progress = state.levels[levelId] ?? (i == 0 ? LevelProgress.unlocked(levelId) : LevelProgress.locked(levelId));
                        final isCurrent = state.currentLevel == levelId || _progressionManager.currentPlayableLevel == levelId;

                        return LevelNode(
                          progress: progress,
                          isCurrent: isCurrent,
                          reducedMotion: false,
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

  Widget _buildBottomWorldTabs(List<dynamic> worlds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withAlpha(90),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(worlds.length.clamp(1, 3), (index) {
          final isSelected = index == _selectedWorldIndex;
          final isUnlocked = index == 0; // World 1 unlocked by default

          return GestureDetector(
            onTap: () {
              if (!isUnlocked) {
                _showLockedDialog('Complete World 1 to unlock World ${index + 1}!');
              } else {
                setState(() => _selectedWorldIndex = index);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF8CE03E), Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF6D4222), Color(0xFF4E2A0E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF8D6E63),
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUnlocked) ...[
                    const Icon(Icons.lock_rounded, color: Color(0xFFFFCA28), size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'World ${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFD7CCC8),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      shadows: isSelected
                          ? const [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
