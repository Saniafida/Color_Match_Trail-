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

          // 3. Top HUD Bar
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GameTopBar(),
          ),

          // 4. Center Content Dialog
          Positioned.fill(
            top: 70,
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
  // 🏆 LEVEL COMPLETE (WIN) DIALOG
  // ==========================================
  Widget _buildWinDialog(dynamic result) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRibbonBanner('LEVEL COMPLETE!'),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF6D4222),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD54F), width: 3.0),
            boxShadow: const [
              BoxShadow(color: Color(0xFF331A0B), offset: Offset(0, 5), blurRadius: 0),
              BoxShadow(color: Colors.black54, offset: Offset(0, 8), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStar(isEarned: result.stars >= 1, size: 54, angle: -0.15),
                  const SizedBox(width: 8),
                  _buildStar(isEarned: result.stars >= 2, size: 68, angle: 0.0),
                  const SizedBox(width: 8),
                  _buildStar(isEarned: result.stars >= 3, size: 54, angle: 0.15),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Score',
                style: TextStyle(color: Color(0xFFFFE082), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${result.finalScore}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 2),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Rewards',
                style: TextStyle(color: Color(0xFFFFF9EC), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4E2A0E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRewardPill('assets/images/icons/icon_coin.png', '150'),
                    _buildRewardPill('assets/images/icons/icon_gem.png', '2'),
                    Image.asset('assets/images/icons/icon_coin.png', width: 28, height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GlossyButton(
                text: 'Replay',
                color: GlossyButtonColor.blue,
                height: 54,
                fontSize: 18,
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
            Expanded(
              child: GlossyButton(
                text: 'Next',
                color: GlossyButtonColor.green,
                height: 54,
                fontSize: 18,
                onPressed: () {
                  final nextId = _resultManager.nextLevelId;
                  _resultManager.reset();
                  if (nextId != null) {
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
                  padding: const EdgeInsets.fromLTRB(26, 70, 26, 16),
                  child: Column(
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
                      const SizedBox(height: 10),

                      // GOAL vs YOU GOT Panel (Real Game Blocks)
                      _buildGoalComparisonPanel(),

                      const SizedBox(height: 10),

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

                      const SizedBox(height: 10),

                      // DON'T GIVE UP! Boosters Section
                      _buildBoostersSuggestionSection(),

                      const Spacer(),

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
  Widget _buildRibbonBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFD32F2F), Color(0xFFB71C1C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1.5, 2), blurRadius: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildStar({required bool isEarned, required double size, required double angle}) {
    return Transform.rotate(
      angle: angle,
      child: Image.asset(
        'assets/images/icons/icon_star_gold.png',
        width: size,
        height: size,
        color: isEarned ? null : Colors.black45,
        colorBlendMode: isEarned ? null : BlendMode.srcATop,
      ),
    );
  }

  Widget _buildRewardPill(String assetPath, String count) {
    return Row(
      children: [
        Image.asset(assetPath, width: 26, height: 26),
        const SizedBox(width: 6),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
