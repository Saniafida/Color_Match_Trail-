import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/screens/achievements/achievements_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.instance.initialize();
  });

  group('AchievementsScreen UI & Claim Enforcement Tests', () {
    testWidgets('1. AchievementsScreen builds and keeps claim disabled for incomplete achievements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('Beginner Adventurer'), findsOneWidget);
      expect(find.text('Master Collector'), findsOneWidget);
      expect(find.text('Block Buster'), findsOneWidget);
      expect(find.text('Combo King'), findsOneWidget);

      // Claim All should NOT be visible when no achievements completed
      expect(find.text('Claim All'), findsNothing);
    });

    testWidgets('2. Completing an achievement enables Claim button and awards coins & gems', (tester) async {
      final coinManager = ServiceLocator.instance.coinManager;
      final gemManager = ServiceLocator.instance.gemManager;
      final statsManager = ServiceLocator.instance.statisticsManager;

      final initialCoins = coinManager.balance;
      final initialGems = gemManager.balance;

      // Complete 5 levels to complete "Beginner Adventurer" (target 5)
      for (int i = 0; i < 5; i++) {
        statsManager.onLevelCompleted(3, 500);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Claim All'), findsOneWidget);

      // Tap Claim All
      await tester.tap(find.text('Claim All'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      // 100 Coins and 2 Gems for levels + 150 Coins and 3 Gems for 15 stars
      expect(coinManager.balance, initialCoins + 250);
      expect(gemManager.balance, initialGems + 5);
    });
  });
}
