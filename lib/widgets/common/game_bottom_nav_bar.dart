import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';

enum GameBottomTab {
  home,
  rewards,
  spin,
  events,
  shop,
}

class GameBottomNavBar extends StatelessWidget {
  final GameBottomTab activeTab;

  const GameBottomNavBar({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3E200C).withAlpha(235),
        border: const Border(
          top: BorderSide(color: Color(0xFFFFD54F), width: 2.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Home
            _buildTabButton(
              context: context,
              tab: GameBottomTab.home,
              label: 'Home',
              iconWidget: const Icon(Icons.home_rounded, color: Color(0xFF4FC3F7), size: 26),
              route: AppRoutes.home,
            ),

            // 2. Rewards
            _buildTabButton(
              context: context,
              tab: GameBottomTab.rewards,
              label: 'Rewards',
              iconWidget: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD54F), size: 26),
              route: AppRoutes.rewards,
            ),

            // 3. Spin
            _buildTabButton(
              context: context,
              tab: GameBottomTab.spin,
              label: 'Spin',
              iconWidget: _buildSpinWheelIcon(),
              route: AppRoutes.rewards, // Opens spin / rewards
              isSpinRoute: true,
            ),

            // 4. Events
            _buildTabButton(
              context: context,
              tab: GameBottomTab.events,
              label: 'Events',
              iconWidget: const Icon(Icons.star_rounded, color: Color(0xFFFFCA28), size: 26),
              route: AppRoutes.events,
            ),

            // 5. Shop
            _buildTabButton(
              context: context,
              tab: GameBottomTab.shop,
              label: 'Shop',
              iconWidget: const Icon(Icons.storefront_rounded, color: Color(0xFFE53935), size: 26),
              route: AppRoutes.shop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required GameBottomTab tab,
    required String label,
    required Widget iconWidget,
    required String route,
    bool isSpinRoute = false,
  }) {
    final isActive = activeTab == tab;

    return GestureDetector(
      onTap: () {
        if (isActive) return;
        if (isSpinRoute) {
          Navigator.pushNamed(context, AppRoutes.rewards, arguments: 'spin');
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFFFEE58), Color(0xFFFFA000), Color(0xFFE65100)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFF8D5325), Color(0xFF6B3C17), Color(0xFF4E2A0E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          border: Border.all(
            color: isActive ? const Color(0xFFFFF9C4) : const Color(0xFFFFD54F),
            width: isActive ? 2.2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive ? const Color(0xFFE65100).withAlpha(180) : const Color(0xFF2C1605),
              offset: const Offset(0, 3),
              blurRadius: isActive ? 4 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF3E200C) : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  shadows: isActive
                      ? [const Shadow(color: Colors.white70, offset: Offset(0, 1), blurRadius: 1)]
                      : [const Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinWheelIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        gradient: const SweepGradient(
          colors: [
            Color(0xFFE91E63),
            Color(0xFFFFEB3B),
            Color(0xFF00E676),
            Color(0xFF29B6F6),
            Color(0xFFFF9800),
            Color(0xFFE91E63),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
