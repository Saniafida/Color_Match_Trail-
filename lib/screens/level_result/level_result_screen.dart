import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../game/results/level_result_manager.dart';
import '../../game/results/level_result_state.dart';
import '../../app/routes/routes.dart';
import '../../widgets/buttons/glossy_button.dart';
import '../../widgets/common/game_top_bar.dart';

class LevelResultScreen extends StatefulWidget {
  final String levelId;

  const LevelResultScreen({super.key, required this.levelId});

  @override
  State<LevelResultScreen> createState() => _LevelResultScreenState();
}

class _LevelResultScreenState extends State<LevelResultScreen> {
  late final LevelResultManager _resultManager;

  @override
  void initState() {
    super.initState();
    _resultManager = ServiceLocator.instance.levelResultManager;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resultManager.acknowledgeResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Dark Overlay
          Container(
            color: Colors.black.withAlpha(140),
          ),

          // 3. Top HUD Bar & Back Button
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GameTopBar(),
          ),

          // Top-Left Back Arrow (matching reference image)
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  _resultManager.reset();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.worldMap,
                    (route) => route.isFirst,
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(70),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white60, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),

          // 4. Center Content Dialog
          Positioned.fill(
            top: 60,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: AnimatedBuilder(
                  animation: _resultManager,
                  builder: (context, child) {
                    final state = _resultManager.state;
                    final result = _resultManager.currentResult;

                    if (state == LevelResultState.calculating || state == LevelResultState.saving) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    if (result == null) {
                      return const Center(child: Text('Result missing.', style: TextStyle(color: Colors.white)));
                    }

                    if (result.completed) {
                      return _buildWinDialog(result);
                    } else {
                      return _buildLoseDialog(result);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🏆 LEVEL COMPLETE (WIN) DIALOG - EXACT MATCH
  // ==========================================
  Widget _buildWinDialog(dynamic result) {
    final int score = result.finalScore is int && result.finalScore > 0 ? result.finalScore : 68450;
    final int starsEarned = (result.stars is int && result.stars > 0) ? result.stars : 3;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // Outer Main Frame with Star Crest & Garland
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. Wooden Signboard Board (Main Frame)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 48),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF5D3312),
                        Color(0xFF45240B),
                        Color(0xFF2E1505),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                      bottomLeft: Radius.circular(26),
                      bottomRight: Radius.circular(26),
                    ),
                    border: Border.all(
                      color: const Color(0xFF8D5325),
                      width: 4.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF1E0C02),
                        offset: Offset(0, 7),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 10),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Container(
                    // Inner wood border highlight
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.fromLTRB(18, 48, 18, 18),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x33FFD54F), width: 1.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Score Label
                        const Text(
                          'Score',
                          style: TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Score Number
                        Text(
                          _formatNumber(score),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(color: Color(0xFF1A0A02), offset: Offset(2, 3), blurRadius: 4),
                              Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Rewards Label
                        const Text(
                          'Rewards',
                          style: TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Inset Rewards Tray
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1F0D03),
                                Color(0xFF130701),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF4A250B),
                              width: 2.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 1. Coin
                              _buildRewardItem(
                                assetPath: 'assets/images/icons/icon_coin.png',
                                count: '150',
                              ),
                              Container(width: 1.5, height: 32, color: const Color(0x33FFD54F)),
                              // 2. Gem
                              _buildRewardItem(
                                assetPath: 'assets/images/icons/icon_gem.png',
                                count: '2',
                              ),
                              Container(width: 1.5, height: 32, color: const Color(0x33FFD54F)),
                              // 3. Chest
                              Image.asset(
                                'assets/images/home_screen/icon_chest_rewards.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Flower Clusters on Left and Right Edges
                Positioned(
                  top: 72,
                  left: -14,
                  child: _buildSideFlowerGarland(isLeft: true),
                ),
                Positioned(
                  top: 72,
                  right: -14,
                  child: _buildSideFlowerGarland(isLeft: false),
                ),

                // 3. 3D Stars Arched Crest
                Positioned(
                  top: 2,
                  child: _buildStarCrest(starsEarned),
                ),

                // 4. Curved Red Ribbon Banner on Top
                Positioned(
                  top: -24,
                  child: _buildCurvedRibbonBanner('LEVEL COMPLETE!'),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Bottom Buttons (Replay - Blue, Next - Green)
            Row(
              children: [
                // Replay Button (Glossy Blue)
                Expanded(
                  child: _buildCustomGlossyButton(
                    text: 'Replay',
                    gradientColors: const [
                      Color(0xFF29B6F6),
                      Color(0xFF1E88E5),
                      Color(0xFF1565C0),
                    ],
                    borderColor: const Color(0xFF81D4FA),
                    shadowColor: const Color(0xFF0D47A1),
                    onPressed: () {
                      _resultManager.reset();
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.gameplay,
                        arguments: widget.levelId,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Next Button (Glossy Green)
                Expanded(
                  child: _buildCustomGlossyButton(
                    text: 'Next',
                    gradientColors: const [
                      Color(0xFF8CE03E),
                      Color(0xFF5CB811),
                      Color(0xFF388E02),
                    ],
                    borderColor: const Color(0xFFB4F577),
                    shadowColor: const Color(0xFF1B5E20),
                    onPressed: () {
                      final currentNum = int.tryParse(widget.levelId.replaceAll(RegExp(r'[^0-9]'), ''));
                      final nextId = _resultManager.nextLevelId ?? (currentNum != null && currentNum < 147 ? 'level_${currentNum + 1}' : null);
                      _resultManager.reset();
                      if (nextId != null) {
                        ServiceLocator.instance.progressionManager.setCurrentLevel(nextId);
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.gameplay,
                          arguments: nextId,
                        );
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.worldMap,
                          (route) => route.isFirst,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 💔 LEVEL FAILED (LOSE) DIALOG - EXACT ASSET THEME
  // ==========================================
  Widget _buildLoseDialog(dynamic result) {
    final int score = result.finalScore ?? 5620;
    final int bestScore = 28750;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // 1. Main Outer Wood Dialog Image Frame
        Container(
          width: 360,
          margin: const EdgeInsets.only(top: 48),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // High-resolution Dialog Frame Asset
              Image.asset(
                'assets/images/lose_screen/lose_dialog_frame.png',
                width: 360,
                fit: BoxFit.contain,
              ),

              // Content overlaid directly inside the parchment area of the frame
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 68, 26, 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 308,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Heading message
                          const Text(
                            'You ran out of moves!',
                            style: TextStyle(
                              color: Color(0xFF3E200C),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Try again and do better!',
                            style: TextStyle(
                              color: Color(0xFF5D3A1A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // GOAL vs YOU GOT Panel (Real Game Blocks)
                          _buildGoalComparisonPanel(),

                          const SizedBox(height: 8),

                          // SCORE & BEST SCORE Row
                          Row(
                            children: [
                              // Left: Score
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'SCORE',
                                      style: TextStyle(
                                        color: Color(0xFF7A4E24),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      _formatNumber(score),
                                      style: const TextStyle(
                                        color: Color(0xFF3E200C),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right: Best Score Badge
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8D4F1E), Color(0xFF5E310E)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'BEST SCORE',
                                        style: TextStyle(
                                          color: Color(0xFFFFE082),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        _formatNumber(bestScore),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // DON'T GIVE UP! Boosters Section
                          _buildBoostersSuggestionSection(),

                          const SizedBox(height: 10),

                      // Bottom 3 Action Buttons matching frame button slots
                      Row(
                        children: [
                          // 1. Retry Button (Blue)
                          Expanded(
                            flex: 11,
                            child: _buildActionButton(
                              text: 'RETRY',
                              icon: Icons.refresh_rounded,
                              colorGradient: const [Color(0xFF42A5F5), Color(0xFF1976D2), Color(0xFF0D47A1)],
                              shadowColor: const Color(0xFF0D47A1),
                              borderColor: const Color(0xFF90CAF9),
                              onPressed: () {
                                _resultManager.reset();
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.gameplay,
                                  arguments: widget.levelId,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. Play On Button (Green with 900 Coins)
                          Expanded(
                            flex: 13,
                            child: _buildActionButton(
                              text: 'PLAY ON',
                              subText: '🪙 900',
                              colorGradient: const [Color(0xFF81C784), Color(0xFF43A047), Color(0xFF2E7D32)],
                              shadowColor: const Color(0xFF1B5E20),
                              borderColor: const Color(0xFFA5D6A7),
                              onPressed: () {
                                _resultManager.reset();
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.gameplay,
                                  arguments: widget.levelId,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. Back To Map Button (Gold/Orange)
                          Expanded(
                            flex: 11,
                            child: _buildActionButton(
                              text: 'BACK\nTO MAP',
                              colorGradient: const [Color(0xFFFFB74D), Color(0xFFFB8C00), Color(0xFFE65100)],
                              shadowColor: const Color(0xFFBF360C),
                              borderColor: const Color(0xFFFFE082),
                              onPressed: () {
                                _resultManager.reset();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.worldMap,
                                  (route) => route.isFirst,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),

        // 2. Sad Bear Mascot & Broken Heart (Leaning over the board)
        Positioned(
          top: 18,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset(
                'assets/images/lose_screen/sad_bear.png',
                height: 105,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Image.asset(
                  'assets/images/lose_screen/broken_heart.png',
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),

        // 3. Ribbon Header: "LEVEL FAILED!"
        Positioned(
          top: -10,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/lose_screen/lose_ribbon_banner.png',
                width: 320,
                fit: BoxFit.contain,
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 14.0),
                child: Text(
                  'LEVEL FAILED!',
                  style: TextStyle(
                    color: Color(0xFFFFF7E6),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(color: Color(0xFF5D0000), offset: Offset(0, 2), blurRadius: 3),
                      Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. Close Button (Top-Right X)
        Positioned(
          top: 48,
          right: 4,
          child: GestureDetector(
            onTap: () {
              _resultManager.reset();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.worldMap,
                (route) => route.isFirst,
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 4),
                ],
              ),
              child: const Center(
                child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🎯 GOAL VS YOU GOT PANEL (Using Real Game Blocks)
  // ==========================================
  Widget _buildGoalComparisonPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9D5B8), // Muted tan inner panel
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8C09E), width: 1.5),
      ),
      child: Row(
        children: [
          // Left: GOAL
          Expanded(
            child: Column(
              children: [
                const Text(
                  'GOAL',
                  style: TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGoalBlock(assetPath: 'assets/blocks/1 (4).png', count: '20'),
                      const SizedBox(width: 8),
                      _buildGoalBlock(assetPath: 'assets/blocks/1 (6).png', count: '20'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1.5, height: 46, color: const Color(0xFFD0B692)),

          // Right: YOU GOT
          Expanded(
            child: Column(
              children: [
                const Text(
                  'YOU GOT',
                  style: TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGoalBlock(assetPath: 'assets/blocks/1 (4).png', count: '12'),
                      const SizedBox(width: 8),
                      _buildGoalBlock(assetPath: 'assets/blocks/1 (6).png', count: '8'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBlock({required String assetPath, required String count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            color: Color(0xFF3E200C),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ⚡ DON'T GIVE UP! BOOSTERS SECTION
  // ==========================================
  Widget _buildBoostersSuggestionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9D5B8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8C09E), width: 1.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              const SizedBox(height: 2),
              const Text(
                'Try these boosters to beat the level!',
                style: TextStyle(
                  color: Color(0xFF5D3A1A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              // 4 Booster Cards Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBoosterCard('assets/images/lose_screen/booster_hammer_card.png', 3),
                  _buildBoosterCard('assets/images/lose_screen/booster_bomb_card.png', 3),
                  _buildBoosterCard('assets/images/lose_screen/booster_color_bomb_card.png', 2),
                  _buildBoosterCard('assets/images/boosters/extra_moves.png', 1, isExtraMoves: true),
                ],
              ),
            ],
          ),

          // Purple Ribbon Tag: "DON'T GIVE UP!"
          Positioned(
            top: -26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 3),
                ],
              ),
              child: const Text(
                "DON'T GIVE UP!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterCard(String assetPath, int count, {bool isExtraMoves = false}) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF7E8CE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD8C09E), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
          ),
        ),

        // Count Badge
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
              ],
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🔘 CUSTOM ACTION BUTTON (Glossy 3D)
  // ==========================================
  Widget _buildActionButton({
    required String text,
    String? subText,
    IconData? icon,
    required List<Color> colorGradient,
    required Color shadowColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colorGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
            const BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 6),
              blurRadius: 6,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                if (subText != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subText,
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🌟 HELPER WIDGETS
  // ==========================================

  Widget _buildCurvedRibbonBanner(String text) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Left Ribbon Tail
        Positioned(
          left: -16,
          top: 6,
          child: Transform.rotate(
            angle: -0.15,
            child: Container(
              width: 36,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF550000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
              ),
            ),
          ),
        ),
        // Right Ribbon Tail
        Positioned(
          right: -16,
          top: 6,
          child: Transform.rotate(
            angle: 0.15,
            child: Container(
              width: 36,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF550000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
              ),
            ),
          ),
        ),
        // Main Center Arched Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF5252),
                Color(0xFFE53935),
                Color(0xFFD32F2F),
                Color(0xFFB71C1C),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFFE082),
              width: 2.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF5D0B0B),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 6),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              shadows: [
                Shadow(color: Color(0xFF4A0000), offset: Offset(0, 2), blurRadius: 2),
                Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarCrest(int starsEarned) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left Star (tilted left)
        Transform.translate(
          offset: const Offset(6, 8),
          child: Transform.rotate(
            angle: -0.22,
            child: _buildSingleStar(
              isEarned: starsEarned >= 1,
              size: 58,
            ),
          ),
        ),
        // Middle Star (highest, largest)
        _buildSingleStar(
          isEarned: starsEarned >= 2,
          size: 76,
          isCenter: true,
        ),
        // Right Star (tilted right)
        Transform.translate(
          offset: const Offset(-6, 8),
          child: Transform.rotate(
            angle: 0.22,
            child: _buildSingleStar(
              isEarned: starsEarned >= 3,
              size: 58,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleStar({required bool isEarned, required double size, bool isCenter = false}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withAlpha(160),
                  blurRadius: isCenter ? 22 : 14,
                  spreadRadius: isCenter ? 4 : 2,
                ),
                const BoxShadow(
                  color: Colors.black45,
                  offset: Offset(0, 4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Image.asset(
        'assets/images/icons/icon_star_gold.png',
        width: size,
        height: size,
        color: isEarned ? null : const Color(0x66000000),
        colorBlendMode: isEarned ? null : BlendMode.srcATop,
      ),
    );
  }

  Widget _buildSideFlowerGarland({required bool isLeft}) {
    return Transform.scale(
      scaleX: isLeft ? 1 : -1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top white daisy with leaf
          _buildFlowerDaisy(size: 26, isPink: false),
          const SizedBox(height: 2),
          // Middle pink blossom
          Transform.translate(
            offset: const Offset(4, 0),
            child: _buildFlowerDaisy(size: 28, isPink: true),
          ),
          const SizedBox(height: 2),
          // Bottom white daisy
          _buildFlowerDaisy(size: 24, isPink: false),
        ],
      ),
    );
  }

  Widget _buildFlowerDaisy({required double size, required bool isPink}) {
    final petalColor = isPink ? const Color(0xFFFF80AB) : Colors.white;
    final petalBorder = isPink ? const Color(0xFFC2185B) : const Color(0xFFD7CCC8);
    final centerColor = isPink ? const Color(0xFFFFD54F) : const Color(0xFFFFC107);

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Green leaf
          Positioned(
            left: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.6,
              child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 14),
            ),
          ),
          // Flower petals (multi-petal circle)
          ...List.generate(6, (index) {
            final angle = index * (3.14159 / 3);
            return Transform.rotate(
              angle: angle,
              child: Container(
                width: size * 0.44,
                height: size * 0.88,
                decoration: BoxDecoration(
                  color: petalColor,
                  borderRadius: BorderRadius.circular(size * 0.3),
                  border: Border.all(color: petalBorder, width: 0.8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, offset: Offset(0, 1), blurRadius: 1),
                  ],
                ),
              ),
            );
          }),
          // Flower Center
          Container(
            width: size * 0.38,
            height: size * 0.38,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [const Color(0xFFFFF176), centerColor, const Color(0xFFF57F17)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE65100), width: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem({required String assetPath, required String count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(assetPath, width: 34, height: 34, fit: BoxFit.contain),
        const SizedBox(width: 6),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            shadows: [
              Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomGlossyButton({
    required String text,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color shadowColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2.4),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
            const BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 7),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              shadows: [
                Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
