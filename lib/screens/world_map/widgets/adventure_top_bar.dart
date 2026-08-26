import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/service_locator.dart';
import '../../shop/shop_screen.dart';
import '../../settings/settings_screen.dart';

class AdventureTopBar extends StatelessWidget {
  final int coins;
  final int gems;
  final int hearts;
  final String heartsLabel;
  final VoidCallback onBack;

  const AdventureTopBar({
    super.key,
    required this.coins,
    this.gems = 230,
    this.hearts = 5,
    this.heartsLabel = 'Full',
    required this.onBack,
  });

  void _openShop(BuildContext context) {
    HapticFeedback.selectionClick();
    ServiceLocator.instance.audioManager.playButtonClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    HapticFeedback.selectionClick();
    ServiceLocator.instance.audioManager.playButtonClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Circular Wooden Back Button
          _buildCircleWoodButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 20,
            onPressed: () {
              HapticFeedback.lightImpact();
              ServiceLocator.instance.audioManager.playButtonClick();
              onBack();
            },
          ),

          const SizedBox(width: 4),

          // 2. Resource Capsules (Hearts, Coins, Gems)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hearts Capsule
                  _buildResourcePill(
                    context: context,
                    leading: _buildHeartBadge(hearts),
                    label: heartsLabel,
                    onAdd: () => _openShop(context),
                  ),
                  const SizedBox(width: 6),

                  // Coins Capsule
                  _buildResourcePill(
                    context: context,
                    leading: Image.asset(
                      'assets/images/icons/icon_coin.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 22),
                    ),
                    label: '$coins',
                    onAdd: () => _openShop(context),
                  ),
                  const SizedBox(width: 6),

                  // Gems Capsule
                  _buildResourcePill(
                    context: context,
                    leading: Image.asset(
                      'assets/images/icons/icon_gem.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.diamond_rounded, color: Color(0xFFBA68C8), size: 20),
                    ),
                    label: '$gems',
                    onAdd: () => _openShop(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 3. Circular Wooden Settings Gear Button
          _buildCircleWoodButton(
            icon: Icons.settings_rounded,
            iconSize: 22,
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleWoodButton({
    required IconData icon,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.2, -0.3),
            radius: 0.85,
            colors: [
              Color(0xFFB57038),
              Color(0xFF824B1E),
              Color(0xFF563012),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFE5B57A),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
            const BoxShadow(
              color: Color(0xFFF9D8A5),
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: const Color(0xFFFFF7EA),
            size: iconSize,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartBadge(int count) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 0.8,
          colors: [
            Color(0xFFFF5252),
            Color(0xFFD32F2F),
            Color(0xFF8B0000),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66FF1744),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourcePill({
    required BuildContext context,
    required Widget leading,
    required String label,
    required VoidCallback onAdd,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 3, right: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4B886),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4E342E),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          // Circular Green Plus Button
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.2, -0.3),
                  radius: 0.85,
                  colors: [
                    Color(0xFF76D636),
                    Color(0xFF4CAF50),
                    Color(0xFF2E7D32),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFDCEDC8),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x662E7D32),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
