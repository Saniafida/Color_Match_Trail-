import 'package:flutter/material.dart';
import '../../../app/routes/routes.dart';
import '../../../core/services/service_locator.dart';
import 'home_menu_button.dart';

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  final _dailyManager = ServiceLocator.instance.dailyChallengeManager;

  @override
  void initState() {
    super.initState();
    _dailyManager.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _dailyManager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dailyManager = ServiceLocator.instance.dailyChallengeManager;
    final hasActionableDaily = dailyManager.currentProgress != null &&
        (dailyManager.canClaimReward || dailyManager.currentProgress!.currentValue == 0);

    final eventManager = ServiceLocator.instance.eventManager;
    final hasActionableEvent = eventManager.hasActiveEvents || eventManager.hasUnclaimedRewards;

    final loc = ServiceLocator.instance.localizationManager;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeMenuButton(
          icon: Icons.map,
          label: loc.translate('home.map'),
          onTap: () => Navigator.pushNamed(context, AppRoutes.levelSelect),
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            HomeMenuButton(
              icon: Icons.emoji_events,
              label: loc.translate('home.events'),
              onTap: () => Navigator.pushNamed(context, AppRoutes.events),
            ),
            if (hasActionableEvent)
              Positioned(
                top: 0,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        HomeMenuButton(
          icon: Icons.shopping_cart,
          label: loc.translate('home.shop'),
          onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
        ),
        HomeMenuButton(
          icon: Icons.emoji_events,
          label: loc.translate('home.achievements'),
          onTap: () => Navigator.pushNamed(context, AppRoutes.achievements),
        ),
        HomeMenuButton(
          icon: Icons.bar_chart,
          label: loc.translate('home.stats'),
          onTap: () => Navigator.pushNamed(context, AppRoutes.statistics),
        ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            HomeMenuButton(
              icon: Icons.star_outline,
              label: loc.translate('home.daily'),
              onTap: () => Navigator.pushNamed(context, AppRoutes.challenges),
            ),
            if (hasActionableDaily)
              Positioned(
                top: 0,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        HomeMenuButton(
          icon: Icons.settings,
          label: loc.translate('home.settings'),
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ],
    );
  }
}
