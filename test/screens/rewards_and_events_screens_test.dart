import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/screens/rewards/rewards_screen.dart';
import 'package:color_match_trail/screens/rewards/daily_bonus_screen.dart';
import 'package:color_match_trail/screens/rewards/spin_wheel_screen.dart';
import 'package:color_match_trail/screens/events/events_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.instance.initialize();
  });

  group('Rewards, Daily Bonus, Spin Wheel & Events Screens Tests', () {
    testWidgets('1. RewardsScreen builds and displays quests and Claim All button', (tester) async {
      final coinManager = ServiceLocator.instance.coinManager;
      final gemManager = ServiceLocator.instance.gemManager;
      final statsManager = ServiceLocator.instance.statisticsManager;

      // Complete quests via real stats
      statsManager.onLevelCompleted(3, 6000);
      statsManager.onLevelCompleted(3, 6000);
      statsManager.onLevelCompleted(3, 6000);
      statsManager.onBlocksCleared(60);
      statsManager.onBoosterUsed();
      statsManager.onBoosterUsed();
      statsManager.onDailyChallengeCompleted();

      final initialCoins = coinManager.balance;
      final initialGems = gemManager.balance;

      await tester.pumpWidget(
        const MaterialApp(
          home: RewardsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rewards'), findsWidgets);
      expect(find.text('Play games and win amazing rewards!'), findsOneWidget);
      expect(find.text('7-Day Login Bonus Available!'), findsNothing); // Removed
      expect(find.text('Complete 3 Levels'), findsOneWidget);
      expect(find.text('Clear 50 Blocks'), findsOneWidget);
      expect(find.text('Score 5,000 Points'), findsOneWidget);
      expect(find.text('Claim All'), findsOneWidget);

      // Tap Claim All
      await tester.tap(find.text('Claim All'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      expect(coinManager.balance, initialCoins + 350);
      expect(gemManager.balance, initialGems + 5);
    });

    testWidgets('2. DailyBonusScreen builds and displays 7 days rewards and chest and claims reward', (tester) async {
      final gemManager = ServiceLocator.instance.gemManager;
      final initialGems = gemManager.balance;

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyBonusScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Bonus'), findsWidgets);
      expect(find.text('Come back every day and get bigger rewards!'), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('Day 3'), findsOneWidget);
      expect(find.text('Day 4'), findsOneWidget);
      expect(find.text('Day 5'), findsOneWidget);
      expect(find.text('Day 6'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Day 7'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Day 7'), findsOneWidget);
      expect(find.text('Big Reward!'), findsOneWidget);
      expect(find.text('Claim'), findsOneWidget);

      // Tap Claim button (Day 4 reward is 10 gems)
      await tester.tap(find.text('Claim'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      expect(gemManager.balance, initialGems + 10);
      expect(find.text('Claimed'), findsOneWidget);
    });

    testWidgets('3. SpinWheelScreen builds and displays wheel and Spin button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SpinWheelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spin Wheel'), findsWidgets);
      expect(find.text('Spin and win exciting prizes!'), findsOneWidget);
      expect(find.text('Spin'), findsWidgets);
      expect(find.text('Daily Free Spin: 1'), findsOneWidget);
    });

    testWidgets('4. EventsScreen builds and displays 3 active event cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EventsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Events'), findsWidgets);
      expect(find.text('Join events and win awesome rewards!'), findsOneWidget);
      expect(find.text('Rainbow Rush'), findsOneWidget);
      expect(find.text('Star Tournament'), findsOneWidget);
      expect(find.text('Booster Blitz'), findsOneWidget);
      expect(find.text('More events coming soon!'), findsOneWidget);
    });
  });
}
