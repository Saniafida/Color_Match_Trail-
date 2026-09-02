import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_sign_header.dart';
import '../../widgets/buttons/glossy_button.dart';
import '../../widgets/dialogs/out_of_hearts_dialog.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final _manager = ServiceLocator.instance.dailyChallengeManager;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _manager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
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

          // 2. Dark contrast overlay
          Container(
            color: Colors.black.withAlpha(50),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                WoodSignHeader(
                  title: 'Daily Challenge',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 12),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "Complete today's puzzle and win rewards!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Wooden Container with Day 1 - Day 4 cards
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D4222), // Wood frame
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 3.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF331A0B), offset: Offset(0, 4), blurRadius: 0),
                      BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDayCard('Day 1', '100', isCompleted: true, isActive: false),
                      _buildDayCard('Day 2', '150', isCompleted: true, isActive: false),
                      _buildDayCard('Day 3', '200', isCompleted: true, isActive: false),
                      _buildDayCard('Day 4', '250', isCompleted: false, isActive: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Big Glossy Green Play Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: GlossyButton(
                    text: 'Play',
                    color: GlossyButtonColor.green,
                    height: 56,
                    fontSize: 22,
                    onPressed: () async {
                      final livesManager = ServiceLocator.instance.livesManager;
                      if (!livesManager.hasLives) {
                        final refilled = await OutOfHeartsDialog.show(context);
                        if (!refilled || !livesManager.hasLives) return;
                      }
                      if (context.mounted) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.gameplay,
                          arguments: 'level_1',
                        );
                      }
                    },
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String dayTitle, String coins, {required bool isCompleted, required bool isActive}) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF9EC) : const Color(0xFF5D3A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? const Color(0xFFFFD54F) : const Color(0xFF8D6E63),
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withAlpha(120),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayTitle,
            style: TextStyle(
              color: isActive ? const Color(0xFF3E200C) : const Color(0xFFD7CCC8),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),

          // Checkmark or Star Badge
          if (isCompleted)
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 24),
            )
          else if (isActive)
            Image.asset(
              'assets/images/icons/icon_star_gold.png',
              width: 36,
              height: 36,
            )
          else
            const Icon(Icons.lock_rounded, color: Colors.white38, size: 30),

          const SizedBox(height: 8),

          // Coin reward
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/icons/icon_coin.png', width: 16, height: 16),
              const SizedBox(width: 3),
              Text(
                coins,
                style: TextStyle(
                  color: isActive ? const Color(0xFFE65100) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
