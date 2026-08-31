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

  @override
  Widget build(BuildContext context) {
    final coinManager = ServiceLocator.instance.coinManager;
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
            child: Column(
              children: [
                // Top HUD Bar: Back Button, Hearts, Coins, Gems, Settings
                AdventureTopBar(
                  coins: coins,
                  gems: 230,
                  hearts: 5,
                  heartsLabel: 'Full',
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
            ),
          ),
        ],
      ),
    );
  }
}
