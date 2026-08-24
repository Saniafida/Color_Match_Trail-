import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/world_map/world_map_screen.dart';
import '../../screens/level_select/level_select_screen.dart';
import '../../screens/gameplay/gameplay_screen.dart';
import '../../screens/level_result/level_result_screen.dart';
import '../../screens/challenges/daily_challenge_screen.dart';
import '../../screens/events/events_screen.dart';
import '../../screens/events/event_detail_screen.dart';
import '../../screens/shop/shop_screen.dart';
import '../../screens/rewards/rewards_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/achievements/achievements_screen.dart';
import '../../screens/statistics/statistics_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';

import '../../screens/settings/theme_screen.dart';
import '../../screens/mini_games/tile_sort_screen.dart';
import '../../screens/mini_games/tile_stack_screen.dart';
import '../../screens/mini_games/tile_drop_screen.dart';
import '../../screens/mini_games/tile_swap_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String worldMap = '/world_map';
  static const String levelSelect = '/level_select';
  static const String gameplay = '/gameplay';
  static const String levelResult = '/level_result';
  static const String challenges = '/challenges';
  static const String events = '/events';
  static const String eventDetail = '/event_detail';
  static const String shop = '/shop';
  static const String rewards = '/rewards';
  static const String settings = '/settings';
  static const String themes = '/themes';
  static const String achievements = '/achievements';
  static const String statistics = '/statistics';
  static const String tileSort = '/tile_sort';
  static const String tileStack = '/tile_stack';
  static const String tileDrop = '/tile_drop';
  static const String tileSwap = '/tile_swap';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case worldMap:
        return MaterialPageRoute(builder: (_) => const WorldMapScreen());
      case levelSelect:
        return MaterialPageRoute(builder: (_) => const LevelSelectScreen());
      case gameplay:
        final levelId = routeSettings.arguments as String? ?? "level_1";
        return MaterialPageRoute(builder: (_) => GameplayScreen(levelId: levelId));
      case levelResult:
        final levelId = routeSettings.arguments as String? ?? "level_1";
        return MaterialPageRoute(builder: (_) => LevelResultScreen(levelId: levelId));
      case challenges:
        return MaterialPageRoute(builder: (_) => const DailyChallengeScreen());
      case events:
        return MaterialPageRoute(builder: (_) => const EventsScreen());
      case eventDetail:
        final eventId = routeSettings.arguments as String;
        return MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId));
      case shop:
        return MaterialPageRoute(builder: (_) => const ShopScreen());
      case rewards:
        return MaterialPageRoute(builder: (_) => const RewardsScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case themes:
        return MaterialPageRoute(builder: (_) => const ThemeScreen());
      case achievements:
        return MaterialPageRoute(builder: (_) => const AchievementsScreen());
      case statistics:
        return MaterialPageRoute(builder: (_) => const StatisticsScreen());
      case tileSort:
        return MaterialPageRoute(builder: (_) => const TileSortScreen());
      case tileStack:
        return MaterialPageRoute(builder: (_) => const TileStackScreen());
      case tileDrop:
        final initialLvl = routeSettings.arguments as int? ?? 1;
        return MaterialPageRoute(
          builder: (_) => TileDropScreen(initialLevel: initialLvl),
        );
      case tileSwap:
        final initialLvl = routeSettings.arguments as int? ?? 1;
        return MaterialPageRoute(
          builder: (_) => TileSwapScreen(startingLevel: initialLvl),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
