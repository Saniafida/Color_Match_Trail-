import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/screens/home/home_screen.dart';
import 'package:color_match_trail/widgets/dialogs/hearts_full_dialog.dart';
import 'package:color_match_trail/widgets/dialogs/out_of_hearts_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.instance.initialize();
  });

  group('Hearts Full Dialog and Home Screen Heart Tap Tests', () {
    setUp(() async {
      final livesManager = ServiceLocator.instance.livesManager;
      await livesManager.initialize();
    });

    testWidgets('1. HeartsFullDialog displays expected UI elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeartsFullDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HEARTS FULL!'), findsOneWidget);
      expect(find.text('Your Hearts Are Full!'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('PLAY NOW'), findsOneWidget);
      expect(find.byKey(const ValueKey('hearts_full_play_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('hearts_full_close_btn')), findsOneWidget);
      expect(find.text('♥ Ready for endless adventure! ♥'), findsOneWidget);
    });

    testWidgets('2. OutOfHeartsDialog.show automatically routes to HeartsFullDialog when lives are full', (tester) async {
      final livesManager = ServiceLocator.instance.livesManager;
      livesManager.setLivesForTesting(5);
      expect(livesManager.isFull, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => OutOfHeartsDialog.show(ctx),
                child: const Text('Tap Hearts'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Hearts'));
      await tester.pumpAndSettle();

      // Should show HeartsFullDialog, NOT OutOfHeartsDialog
      expect(find.text('HEARTS FULL!'), findsOneWidget);
      expect(find.text('Your Hearts Are Full!'), findsOneWidget);
      expect(find.text('Out of Hearts!'), findsNothing);
      expect(find.text('You are out of hearts!'), findsNothing);

      // Close it
      await tester.tap(find.byKey(const ValueKey('hearts_full_close_btn')));
      await tester.pumpAndSettle();

      expect(find.text('HEARTS FULL!'), findsNothing);
    });

    testWidgets('3. OutOfHeartsDialog.show shows refill when lives are 0', (tester) async {
      final livesManager = ServiceLocator.instance.livesManager;
      livesManager.setLivesForTesting(0);
      expect(livesManager.isFull, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => OutOfHeartsDialog.show(ctx),
                child: const Text('Tap Hearts'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Hearts'));
      await tester.pumpAndSettle();

      expect(find.text('Out of Hearts!'), findsOneWidget);
      expect(find.text('You are out of hearts!'), findsOneWidget);
      expect(find.text('HEARTS FULL!'), findsNothing);
    });

    testWidgets('4. HomeScreen Heart Pill tap opens HeartsFullDialog when lives are full', (tester) async {
      tester.view.physicalSize = const Size(450, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final livesManager = ServiceLocator.instance.livesManager;
      livesManager.setLivesForTesting(5);
      expect(livesManager.isFull, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the hearts stat pill (showing '5' or 'Full')
      final heartPill = find.byWidgetPredicate((widget) {
        return widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName.contains('icon_heart');
      });
      expect(heartPill, findsWidgets);

      // Tap the first heart icon
      await tester.tap(heartPill.first);
      await tester.pumpAndSettle();

      // Verify HeartsFullDialog opens
      expect(find.text('HEARTS FULL!'), findsOneWidget);
      expect(find.text('Your Hearts Are Full!'), findsOneWidget);
      expect(find.text('Out of Hearts!'), findsNothing);
    });
  });
}
