import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_sign_header.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _achManager = ServiceLocator.instance.achievementManager;

  @override
  void initState() {
    super.initState();
    _achManager.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _achManager.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
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

          // 2. Overlay
          Container(
            color: Colors.black.withAlpha(50),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                WoodSignHeader(
                  title: 'Achievements',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 12),

                // Achievements Wood Container
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EC), // Inner cream canvas
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 6),
                      ],
                    ),
                    child: ListView(
                      children: [
                        _buildAchievementRow(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFFAB47BC),
                          title: 'Beginner',
                          desc: 'Complete 10 levels',
                          current: 10,
                          target: 10,
                          rewardAmount: '100',
                          isGem: true,
                        ),
                        const Divider(color: Color(0xFFE2CCAE), thickness: 1, height: 24),
                        _buildAchievementRow(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFFB300),
                          title: 'Master Collector',
                          desc: 'Collect 500 stars',
                          current: 320,
                          target: 500,
                          rewardAmount: '200',
                          isGem: false,
                        ),
                        const Divider(color: Color(0xFFE2CCAE), thickness: 1, height: 24),
                        _buildAchievementRow(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFFF7043),
                          title: 'Combo King',
                          desc: 'Make 50 combo',
                          current: 30,
                          target: 50,
                          rewardAmount: '150',
                          isGem: true,
                        ),
                        const Divider(color: Color(0xFFE2CCAE), thickness: 1, height: 24),
                        _buildAchievementRow(
                          icon: Icons.military_tech_rounded,
                          iconColor: const Color(0xFFE53935),
                          title: 'Level Crusher',
                          desc: 'Complete 100 levels',
                          current: 74,
                          target: 100,
                          rewardAmount: '300',
                          isGem: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required int current,
    required int target,
    required String rewardAmount,
    required bool isGem,
  }) {
    final progressFactor = (current / target).clamp(0.0, 1.0);

    return Row(
      children: [
        // Badge Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0D4),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(width: 12),

        // Title, description and progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF3E200C),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF8D6E63),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              // Progress Bar
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7CCC8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progressFactor,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8CE03E), Color(0xFF4CAF50)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '$current/$target',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Reward Badge (Gem or Coin)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isGem ? 'assets/images/icons/icon_gem.png' : 'assets/images/icons/icon_coin.png',
              width: 26,
              height: 26,
            ),
            const SizedBox(height: 2),
            Text(
              rewardAmount,
              style: const TextStyle(
                color: Color(0xFF3E200C),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
