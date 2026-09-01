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
      await tester.pumpWidget(
        const MaterialApp(
          home: RewardsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rewards'), findsWidgets);
      expect(find.text('Play games and win amazing rewards!'), findsOneWidget);
      expect(find.text('Complete 10 Moves'), findsOneWidget);
      expect(find.text('Clear 3 Lines'), findsOneWidget);
      expect(find.text('Score 5000 Points'), findsOneWidget);
      expect(find.text('Claim All'), findsOneWidget);
    });

    testWidgets('2. DailyBonusScreen builds and displays 7 days rewards and chest', (tester) async {
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
