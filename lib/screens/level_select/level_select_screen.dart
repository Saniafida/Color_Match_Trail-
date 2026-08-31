import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../game/progression/progression_manager.dart';
import '../../core/data/game_data_manager.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> with SingleTickerProviderStateMixin {
  late final ProgressionManager _progressionManager;
  late final GameDataManager _dataManager;
  TabController? _tabController;
  final GlobalKey _currentLevelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _progressionManager = ServiceLocator.instance.progressionManager;
    _dataManager = ServiceLocator.instance.gameDataManager;

    final worlds = _dataManager.getAllWorlds();
    final currentPlayable = _progressionManager.currentPlayableLevel;
    int initialIndex = 0;
    for (int i = 0; i < worlds.length; i++) {
      if (worlds[i].levelIds.contains(currentPlayable)) {
        initialIndex = i;
        break;
      }
    }

    if (worlds.isNotEmpty) {
      _tabController = TabController(
        length: worlds.length,
        vsync: this,
        initialIndex: initialIndex.clamp(0, worlds.length - 1),
      );
    }
    _progressionManager.addListener(_onProgressionUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _scrollToCurrentLevel();
        }
      });
    });
  }

  void _scrollToCurrentLevel() {
    final targetContext = _currentLevelKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _progressionManager.removeListener(_onProgressionUpdated);
    super.dispose();
  }

  void _onProgressionUpdated() {
    if (mounted) setState(() {});
  }

  void _playLevel(String levelId) {
    final validation = _progressionManager.validateLevelAccess(levelId);
    if (!validation.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message ?? 'This level is locked.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _progressionManager.setCurrentLevel(levelId);
    Navigator.pushNamed(context, AppRoutes.gameplay, arguments: levelId);
  }

  @override
  Widget build(BuildContext context) {
    final worlds = _dataManager.getAllWorlds();
    final state = _progressionManager.state;

    if (worlds.isEmpty || _tabController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Level')),
        body: const Center(child: Text('No levels available.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Select Level', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.white60,
          tabs: worlds.map((w) => Tab(text: w.titleKey)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: worlds.map((world) {
          final isWorldUnlocked = state.unlockedWorlds.contains(world.worldId);
          if (!isWorldUnlocked) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 64, color: Colors.white30),
                  const SizedBox(height: 16),
                  Text(
                    '${world.titleKey} is Locked',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requires ${world.unlockRequirement} Stars to Unlock',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: world.levelIds.length,
            itemBuilder: (context, index) {
              final levelId = world.levelIds[index];
              final progress = state.levels[levelId];
              final isUnlocked = progress?.unlocked ?? (index == 0 && isWorldUnlocked);
              final stars = progress?.bestStars ?? 0;
              final isCurrent = state.currentLevel == levelId || _progressionManager.currentPlayableLevel == levelId;

              return KeyedSubtree(
                key: isCurrent ? _currentLevelKey : null,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _playLevel(levelId);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                  decoration: BoxDecoration(
                    color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF0B1120),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF38BDF8)
                          : (isUnlocked ? Colors.white24 : Colors.white10),
                      width: isCurrent ? 2.5 : 1.0,
                    ),
                    boxShadow: isCurrent
                        ? const [
                            BoxShadow(color: Color(0x6638BDF8), blurRadius: 8, offset: Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isUnlocked)
                        const Icon(Icons.lock_rounded, color: Colors.white30, size: 28)
                      else ...[
                        Text(
                          levelId.replaceAll(RegExp(r'[^0-9]'), ''),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (starIdx) {
                            return Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: starIdx < stars ? const Color(0xFFFFD700) : Colors.white24,
                            );
                          }),
                        ),
                        if (progress != null && progress.bestScore > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${progress.bestScore}',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            );
            },
          );
        }).toList(),
      ),
    );
  }
}
