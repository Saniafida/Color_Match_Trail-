import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import 'widgets/home_logo.dart';
import 'widgets/home_progress.dart';
import 'widgets/play_button.dart';
import 'widgets/home_menu.dart';
import 'widgets/home_loading.dart';
import 'widgets/home_error.dart';
import '../achievements/widgets/achievement_unlock_popup.dart';
import '../achievements/widgets/milestone_unlock_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AchievementUnlockOverlay.initialize(context);
      MilestoneUnlockOverlay.initialize(context);
    });
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final progressionManager = ServiceLocator.instance.progressionManager;
      progressionManager.initialize();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load progress.';
      });
    }
  }

  void _onPlay(String currentLevelId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.gameplay,
      arguments: currentLevelId,
    );
    // Refresh progress when returning from gameplay
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const HomeLoading();
    }

    if (_error != null) {
      return HomeError(
        message: _error!,
        onRetry: _loadProgress,
      );
    }

    final progressionManager = ServiceLocator.instance.progressionManager;
    final dataManager = ServiceLocator.instance.gameDataManager;
    
    final totalLevels = dataManager.getAllLevels().length;
    final highestUnlocked = progressionManager.unlockedLevels.length;
    final totalStars = progressionManager.totalStars;
    final nextLevelId = progressionManager.getNextPlayableLevel();
    final nextLevelNum = int.tryParse(nextLevelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final isCampaignDone = progressionManager.isCampaignCompleted;

    return Column(
      children: [
        const SizedBox(height: 40),
        // 1. Logo area
        const HomeLogo(),
        const Spacer(flex: 1),
        
        // 2. Progress summary
        HomeProgress(
          highestUnlockedLevel: highestUnlocked,
          totalStars: totalStars,
          totalLevels: totalLevels,
        ),
        const SizedBox(height: 30),
        
        // 3. Primary CTA
        PlayButton(
          currentLevelNumber: nextLevelNum,
          isCampaignCompleted: isCampaignDone,
          onPlay: () => _onPlay(nextLevelId),
        ),
        
        const Spacer(flex: 2),
        
        // 4. Secondary Menu Grid
        const HomeMenu(),
        
        const SizedBox(height: 30),
      ],
    );
  }
}
