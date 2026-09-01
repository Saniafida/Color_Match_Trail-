import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/widgets/dialogs/out_of_hearts_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.instance.initialize();
  });

  group('OutOfHeartsDialog UI and Functionality Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final livesManager = ServiceLocator.instance.livesManager;
      await livesManager.initialize();
      livesManager.setLivesForTesting(0);
    });

    testWidgets('1. OutOfHeartsDialog displays all expected elements correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutOfHeartsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Out of Hearts!'), findsOneWidget);
      expect(find.text('You are out of hearts!'), findsOneWidget);
      expect(find.text('Get more hearts and keep playing.'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.byKey(const ValueKey('out_of_hearts_watch_btn')), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.byKey(const ValueKey('out_of_hearts_coins_btn')), findsOneWidget);
      expect(find.text('♥ Don\'t lose your progress! ♥'), findsOneWidget);
      expect(find.byKey(const ValueKey('out_of_hearts_close_btn')), findsOneWidget);
    });

    testWidgets('2. Tapping Watch refilled lives to 5 and closes dialog', (tester) async {
      final livesManager = ServiceLocator.instance.livesManager;
      expect(livesManager.lives, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => OutOfHeartsDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Out of Hearts!'), findsOneWidget);

      // Tap Watch
      await tester.tap(find.byKey(const ValueKey('out_of_hearts_watch_btn')));
      await tester.pumpAndSettle();

      expect(livesManager.lives, 5);
      expect(find.text('Out of Hearts!'), findsNothing);
    });

    testWidgets('3. Tapping 100 Coins button spends 100 coins and refills lives to 5', (tester) async {
      final livesManager = ServiceLocator.instance.livesManager;
      final coinManager = ServiceLocator.instance.coinManager;
      if (coinManager.balance < 100) {
        await coinManager.addCoins(200);
      }
      final initialBalance = coinManager.balance;

      livesManager.setLivesForTesting(0);
      expect(livesManager.lives, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => OutOfHeartsDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Out of Hearts!'), findsOneWidget);

      // Tap 100 Coins button
      await tester.tap(find.byKey(const ValueKey('out_of_hearts_coins_btn')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      expect(livesManager.lives, 5);
      expect(coinManager.balance, initialBalance - 100);
      expect(find.text('Out of Hearts!'), findsNothing);
    });
  });
}
