import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../game/progression/progression_manager.dart';
import 'widgets/adventure_top_bar.dart';
import 'widgets/adventure_board.dart';
import 'widgets/adventure_play_button.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  late final ProgressionManager _progressionManager;
  int _selectedLevel = 1; // Default starting selected level

  @override
  void initState() {
    super.initState();
    _progressionManager = ServiceLocator.instance.progressionManager;
    _progressionManager.addListener(_onProgressionUpdated);
    _initSelectedLevel();
  }

  void _initSelectedLevel() {
    final currentPlayable = _progressionManager.currentPlayableLevel;
    final num = int.tryParse(currentPlayable.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    _selectedLevel = num;
  }

  @override
  void dispose() {
    _progressionManager.removeListener(_onProgressionUpdated);
    super.dispose();
  }

  void _onProgressionUpdated() {
    if (mounted) {
      setState(() {
        _initSelectedLevel();
      });
    }
  }

  void _playLevel(int levelNumber) async {
    final levelId = 'level_$levelNumber';
    final isUnlocked = _progressionManager.canPlayLevel(levelId);
    if (!isUnlocked) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Level $levelNumber is Locked! Complete Level ${levelNumber - 1} first.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final livesManager = ServiceLocator.instance.livesManager;
    if (!livesManager.hasLives) {
      _showOutOfLivesDialog();
      return;
    }

    _progressionManager.setCurrentLevel(levelId);

    await Navigator.pushNamed(
      context,
      AppRoutes.gameplay,
      arguments: levelId,
    );
    if (mounted) {
      setState(() {
        _initSelectedLevel();
      });
    }
  }

  void _showOutOfLivesDialog() {
    final livesManager = ServiceLocator.instance.livesManager;
    final coinManager = ServiceLocator.instance.coinManager;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF4A250B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 2.5),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, color: Color(0xFFFF5252), size: 28),
            SizedBox(width: 8),
            Text(
              'No Lives Left!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/lose_screen/broken_heart.png',
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text(
              'You have 0 lives left for today.\n5 fresh lives will refill tomorrow automatically!\nOr refill immediately with coins.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: Image.asset('assets/images/icons/icon_coin.png', width: 20, height: 20),
              label: const Text(
                'Refill 5 Lives (200 Coins)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () async {
                final success = await livesManager.refillWithCoins(coinManager);
                if (context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? '❤️ Lives Refilled to Full 5!' : 'Not enough coins to refill!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Wait for Tomorrow', style: TextStyle(color: Colors.white70, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinManager = ServiceLocator.instance.coinManager;
    final livesManager = ServiceLocator.instance.livesManager;
    final coins = coinManager.balance;
    final progressMap = _progressionManager.state.levels;
    final isSelectedUnlocked = _progressionManager.canPlayLevel('level_$_selectedLevel');

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Lush Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Subtle Lighting & Vignette Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),

          // 3. Screen Main Layout
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([coinManager, livesManager, _progressionManager]),
              builder: (context, _) {
                return Column(
                  children: [
                    // Top HUD Bar: Back Button, Hearts, Coins, Gems, Settings
                    AdventureTopBar(
                      coins: coinManager.balance,
                      gems: 230,
                      hearts: livesManager.lives,
                      heartsLabel: livesManager.label,
                      onBack: () => Navigator.pop(context),
                    ),

                // Main Adventure Parchment Board (with Trophy, Banner, and Mosaic Level Grid)
                Expanded(
                  child: AdventureBoard(
                    progressMap: progressMap,
                    selectedLevel: _selectedLevel,
                    totalLevels: 147,
                    onSelectLevel: (lvl) {
                      setState(() {
                        _selectedLevel = lvl;
                      });
                    },
                  ),
                ),

                // Big Glossy 3D Green "LEVEL X" Action Button
                AdventurePlayButton(
                  levelNumber: _selectedLevel,
                  isUnlocked: isSelectedUnlocked,
                  onPlay: () => _playLevel(_selectedLevel),
                ),
              ],
            );
          },
        ),
      ),
    ],
  ),
);
}
}
