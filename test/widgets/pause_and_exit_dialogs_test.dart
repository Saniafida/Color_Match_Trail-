import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/screens/gameplay/widgets/pause_dialog.dart';
import 'package:color_match_trail/screens/gameplay/widgets/exit_level_dialog.dart';
import 'package:color_match_trail/screens/gameplay/widgets/restart_level_dialog.dart';

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

  group('Pause and Confirmation Dialogs Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final livesManager = ServiceLocator.instance.livesManager;
      await livesManager.initialize();
      livesManager.setLivesForTesting(5);
    });

    testWidgets('1. PauseDialog displays all elements and triggers RESUME', (tester) async {
      bool resumed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseDialog(
              onResume: () => resumed = true,
              onRestart: () {},
              onExit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Game Paused'), findsOneWidget);
      expect(find.text('RESUME'), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.text('EXIT'), findsOneWidget);

      await tester.tap(find.text('RESUME'));
      await tester.pumpAndSettle();
      expect(resumed, isTrue);
    });

    testWidgets('2. PauseDialog triggers RESTART and EXIT', (tester) async {
      bool restarted = false;
      bool exited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseDialog(
              onResume: () {},
              onRestart: () => restarted = true,
              onExit: () => exited = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('RESTART'));
      await tester.pumpAndSettle();
      expect(restarted, isTrue);

      await tester.tap(find.text('EXIT'));
      await tester.pumpAndSettle();
      expect(exited, isTrue);
    });

    testWidgets('3. ExitLevelDialog displays 1-life loss warning and handles callbacks', (tester) async {
      bool exited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitLevelDialog(
              onResume: () {},
              onExit: () => exited = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LEAVE LEVEL'), findsOneWidget);
      expect(find.text('Give Up This Level?'), findsOneWidget);
      expect(
        find.text('If you quit now, your level progress will be lost and you will lose 1 life!'),
        findsOneWidget,
      );
      expect(find.text('KEEP PLAYING'), findsOneWidget);
      expect(find.text('QUIT LEVEL'), findsOneWidget);

      // Tap Quit Level
      await tester.tap(find.text('QUIT LEVEL'));
      await tester.pumpAndSettle();
      expect(exited, isTrue);
    });

    testWidgets('4. ExitLevelDialog handles KEEP PLAYING callback', (tester) async {
      bool resumed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitLevelDialog(
              onResume: () => resumed = true,
              onExit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('KEEP PLAYING'));
      await tester.pumpAndSettle();
      expect(resumed, isTrue);
    });

    testWidgets('5. RestartLevelDialog displays 1-life loss warning, badge, and handles RESTART', (tester) async {
      bool restarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestartLevelDialog(
              onResume: () {},
              onRestart: () => restarted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RESTART LEVEL'), findsNWidgets(2)); // banner and button
      expect(find.text('Restart Level?'), findsOneWidget);
      expect(find.text('-1 ❤️'), findsOneWidget);
      expect(
        find.text('If you restart now, your current progress will be lost and you will lose 1 life!'),
        findsOneWidget,
      );
      expect(find.text('KEEP PLAYING'), findsOneWidget);

      // Tap Restart Level button via Key
      await tester.tap(find.byKey(const Key('restart_level_confirm_btn')));
      await tester.pumpAndSettle();
      expect(restarted, isTrue);
    });

    testWidgets('6. RestartLevelDialog handles KEEP PLAYING callback', (tester) async {
      bool resumed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestartLevelDialog(
              onResume: () => resumed = true,
              onRestart: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('KEEP PLAYING'));
      await tester.pumpAndSettle();
      expect(resumed, isTrue);
    });

    testWidgets('7. Life is properly deducted when player confirms exit or restart', (tester) async {
      final livesManager = ServiceLocator.instance.livesManager;
      expect(livesManager.lives, 5);

      // Simulate exit confirmation
      await livesManager.consumeLife();
      expect(livesManager.lives, 4);

      // Simulate restart confirmation
      await livesManager.consumeLife();
      expect(livesManager.lives, 3);
    });

    testWidgets('8. Full flow: Pause -> Exit -> ExitLevelDialog shows -> Confirm Quit deducts 1 life', (tester) async {
      final livesManager = ServiceLocator.instance.livesManager;
      livesManager.setLivesForTesting(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (pauseCtx) => PauseDialog(
                      onResume: () => Navigator.pop(pauseCtx),
                      onRestart: () {},
                      onExit: () {
                        Navigator.pop(pauseCtx);
                        ExitLevelDialog.show(
                          context: context,
                          onResume: () {},
                          onExit: () async {
                            await livesManager.consumeLife();
                          },
                        );
                      },
                    ),
                  );
                },
                child: const Text('PAUSE GAME'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Pause dialog
      await tester.tap(find.text('PAUSE GAME'));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      // Tap Exit
      await tester.tap(find.byKey(const Key('pause_exit_btn')));
      await tester.pumpAndSettle();

      // Verify ExitLevelDialog appears
      expect(find.text('LEAVE LEVEL'), findsOneWidget);
      expect(find.text('Give Up This Level?'), findsOneWidget);

      // Tap Quit Level
      await tester.tap(find.byKey(const Key('exit_level_confirm_btn')));
      await tester.pumpAndSettle();

      // Verify life consumed
      expect(livesManager.lives, 4);
    });

    testWidgets('9. Full flow: Pause -> Restart -> RestartLevelDialog shows -> Confirm Restart deducts 1 life', (tester) async {
      final livesManager = ServiceLocator.instance.livesManager;
      livesManager.setLivesForTesting(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (pauseCtx) => PauseDialog(
                      onResume: () => Navigator.pop(pauseCtx),
                      onRestart: () {
                        Navigator.pop(pauseCtx);
                        RestartLevelDialog.show(
                          context: context,
                          onResume: () {},
                          onRestart: () async {
                            await livesManager.consumeLife();
                          },
                        );
                      },
                      onExit: () {},
                    ),
                  );
                },
                child: const Text('PAUSE GAME'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Pause dialog
      await tester.tap(find.text('PAUSE GAME'));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      // Tap Restart
      await tester.tap(find.byKey(const Key('pause_restart_btn')));
      await tester.pumpAndSettle();

      // Verify RestartLevelDialog appears
      expect(find.text('Restart Level?'), findsOneWidget);
      expect(find.text('-1 ❤️'), findsOneWidget);

      // Tap Restart Level confirm
      await tester.tap(find.byKey(const Key('restart_level_confirm_btn')));
      await tester.pumpAndSettle();

      // Verify life consumed
      expect(livesManager.lives, 4);
    });
  });
}
