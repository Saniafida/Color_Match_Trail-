import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../game/lives/lives_manager.dart';

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
    final coinManager = ServiceLocator.instance.coinManager;
    final livesManager = ServiceLocator.instance.livesManager;
    final progression = ServiceLocator.instance.progressionManager;

    return AnimatedBuilder(
      animation: Listenable.merge([coinManager, livesManager, progression]),
      builder: (context, _) {
        final coins = coinManager.balance;
        final livesLabel = livesManager.label;
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
                value: livesLabel,
                pillBgColor: const Color(0xFFD32F2F),
                hasPlus: true,
                onTap: () => _showLivesRefillDialog(context),
              ),
              const SizedBox(width: 5),

              // Coins Pill
              _buildStatPill(
                imagePath: 'assets/images/icons/icon_coin.png',
                value: '$coins',
                pillBgColor: const Color(0xFFF57F17),
                hasPlus: true,
                onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
              ),
              const SizedBox(width: 5),

              // Gems Pill
              _buildStatPill(
                imagePath: 'assets/images/icons/icon_gem.png',
                value: '230',
                pillBgColor: const Color(0xFF8E24AA),
                hasPlus: true,
                onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
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
      },
    );
  }

  void _showLivesRefillDialog(BuildContext context) {
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
            Icon(Icons.favorite_rounded, color: Color(0xFFFF1744), size: 28),
            SizedBox(width: 8),
            Text(
              'Lives / Hearts',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have ${livesManager.lives} / ${LivesManager.maxLives} Lives',
              style: const TextStyle(color: Color(0xFFFFE082), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '❤️ 5 full lives are given each day automatically!\n1 life is lost when you fail a level.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (!livesManager.isFull)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: Image.asset('assets/images/icons/icon_coin.png', width: 20, height: 20),
                label: const Text(
                  'Refill Full (200 Coins)',
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
            child: const Text('Close', style: TextStyle(color: Colors.white70, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String imagePath,
    required String value,
    required Color pillBgColor,
    bool hasPlus = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
