import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';

class GameTopBar extends StatelessWidget {
  final bool showSettings;
  final bool showProfile;
  final VoidCallback? onSettingsTap;

  const GameTopBar({
    super.key,
    this.showSettings = true,
    this.showProfile = false,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    // Read stats from inventory / progression / coins
    final coinManager = ServiceLocator.instance.coinManager;
    final coins = coinManager.balance;
    final progression = ServiceLocator.instance.progressionManager;
    final level = progression.unlockedLevels.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: showProfile ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          if (showProfile) ...[
            // Avatar with bear icon + Lv. 5
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF5D3A1A).withAlpha(220),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/mascot_bear.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Player',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
                          const SizedBox(width: 2),
                          Text(
                            'Lv. $level',
                            style: const TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],

          // Hearts Pill
          _buildStatPill(
            imagePath: 'assets/images/icons/icon_heart.png',
            value: '5 Full',
            pillBgColor: const Color(0xFFD32F2F),
            hasPlus: true,
          ),
          const SizedBox(width: 5),

          // Coins Pill
          _buildStatPill(
            imagePath: 'assets/images/icons/icon_coin.png',
            value: '$coins',
            pillBgColor: const Color(0xFFF57F17),
            hasPlus: true,
          ),
          const SizedBox(width: 5),

          // Gems Pill
          _buildStatPill(
            imagePath: 'assets/images/icons/icon_gem.png',
            value: '230',
            pillBgColor: const Color(0xFF8E24AA),
            hasPlus: true,
          ),

          if (showSettings) ...[
            const SizedBox(width: 5),
            // Settings Gear Button
            GestureDetector(
              onTap: onSettingsTap ?? () => Navigator.pushNamed(context, AppRoutes.settings),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8D6E63), Color(0xFF5D4037), Color(0xFF3E2723)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      offset: Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String imagePath,
    required String value,
    required Color pillBgColor,
    bool hasPlus = false,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3E200C).withAlpha(220),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            offset: Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon thumbnail
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Value text
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 1),
                ],
              ),
            ),
            if (hasPlus) ...[
              const SizedBox(width: 3),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
