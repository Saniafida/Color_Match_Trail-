import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/core/services/date_service.dart';
import 'package:color_match_trail/game/challenges/daily_challenge_generator.dart';
import 'package:color_match_trail/game/challenges/daily_challenge_manager.dart';
import 'package:color_match_trail/game/challenges/daily_challenge_storage.dart';
import 'package:color_match_trail/game/challenges/daily_challenge_progress.dart';
import 'package:color_match_trail/screens/challenges/daily_challenge_screen.dart';

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

  group('7-Day Daily Challenge System Tests', () {
    late DailyChallengeGenerator generator;
    late DailyChallengeStorage storage;
    late DailyChallengeManager manager;

    setUp(() async {
      generator = DailyChallengeGenerator();
      storage = DailyChallengeStorage(saveManager: ServiceLocator.instance.gameSaveManager);
      await storage.clear();

      manager = DailyChallengeManager(
        dateService: ServiceLocator.instance.dateService,
        challengeStorage: storage,
        gameStorage: ServiceLocator.instance.storage,
        generator: generator,
      );
      await manager.initialize();
    });

    test('1. Generator produces escalating rewards for Day 1 through Day 7', () {
      final d1 = generator.generateForDate('2026-09-12', 1);
      final d2 = generator.generateForDate('2026-09-12', 2);
      final d3 = generator.generateForDate('2026-09-12', 3);
      final d4 = generator.generateForDate('2026-09-12', 4);
      final d5 = generator.generateForDate('2026-09-12', 5);
      final d6 = generator.generateForDate('2026-09-12', 6);
      final d7 = generator.generateForDate('2026-09-12', 7);

      expect(d1.rewardAmount, 100);
      expect(d2.rewardAmount, 150);
      expect(d3.rewardAmount, 200);
      expect(d4.rewardAmount, 250);
      expect(d5.rewardAmount, 300);
      expect(d6.rewardAmount, 350);
      expect(d7.rewardAmount, 500);
    });

    test('2. Manager tracks streak and currentDay correctly (1 to 7)', () async {
      expect(manager.currentDay, 1);
      expect(manager.streak, 1);

      manager.setStreakForTesting(4);
      expect(manager.currentDay, 4);

      manager.setStreakForTesting(7);
      expect(manager.currentDay, 7);
    });

    test('3. Clearing required color blocks completes the challenge and unlocks claim', () async {
      final challenge = manager.currentChallenge!;
      expect(manager.isCompleted, isFalse);
      expect(manager.canClaimReward, isFalse);

      // Clear primary color
      await manager.onColorBlocksCleared(challenge.primaryColor, challenge.primaryTarget);
      expect(manager.isCompleted, isFalse); // Secondary still needed

      // Clear secondary color
      await manager.onColorBlocksCleared(challenge.secondaryColor, challenge.secondaryTarget);
      expect(manager.isCompleted, isTrue);
      expect(manager.canClaimReward, isTrue);

      // Claim reward
      final initialCoins = ServiceLocator.instance.coinManager.balance;
      final claimed = await manager.claimReward();
      expect(claimed, isTrue);
      expect(manager.isRewardClaimed, isTrue);
      expect(ServiceLocator.instance.coinManager.balance, initialCoins + challenge.rewardAmount);
    });

    testWidgets('4. DailyChallengeScreen displays all 7 days and active mission card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DailyChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Daily Challenge'), findsOneWidget);
      expect(find.text('7-DAY REWARD ROAD'), findsOneWidget);

      // Verify all 7 days exist
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('Day 3'), findsOneWidget);
      expect(find.text('Day 4'), findsOneWidget);
      expect(find.text('Day 5'), findsOneWidget);
      expect(find.text('Day 6'), findsOneWidget);
      expect(find.text('Day 7'), findsOneWidget);

      // Verify mission card exists
      expect(find.text("TODAY'S MISSION (DAY 1)"), findsOneWidget);
      expect(find.text('PLAY NOW'), findsOneWidget);
    });

    testWidgets('5. DailyChallengeScreen shows CLAIM REWARD when challenge is completed', (tester) async {
      final challenge = ServiceLocator.instance.dailyChallengeManager.currentChallenge!;
      // Mark as completed
      ServiceLocator.instance.dailyChallengeManager.setProgressForTesting(
        DailyChallengeProgress(
          challengeId: challenge.id,
          currentValue: challenge.primaryTarget,
          currentValue2: challenge.secondaryTarget,
          targetValue: challenge.primaryTarget,
          targetValue2: challenge.secondaryTarget,
          completed: true,
          rewardClaimed: false,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CLAIM REWARD'), findsOneWidget);
      expect(find.text('COMPLETED!'), findsOneWidget);
    });

    testWidgets('6. DailyChallengeScreen shows DONE TODAY and PLAY MORE when claimed', (tester) async {
      final challenge = ServiceLocator.instance.dailyChallengeManager.currentChallenge!;
      // Mark as claimed
      ServiceLocator.instance.dailyChallengeManager.setProgressForTesting(
        DailyChallengeProgress(
          challengeId: challenge.id,
          currentValue: challenge.primaryTarget,
          currentValue2: challenge.secondaryTarget,
          targetValue: challenge.primaryTarget,
          targetValue2: challenge.secondaryTarget,
          completed: true,
          rewardClaimed: true,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DONE TODAY!'), findsOneWidget);
      expect(find.text('PLAY MORE'), findsOneWidget);
      expect(find.text('CLAIMED'), findsOneWidget);
    });

    testWidgets('7. DailyChallengeScreen renders without any overflow on compact screens (320x568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      FlutterErrorDetails? errorDetails;
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();
      FlutterError.onError = oldHandler;

      if (errorDetails != null) {
        print('EXACT OVERFLOW CAUSE:');
        print(errorDetails!.toString());
      }
      expect(errorDetails, isNull);
      expect(find.byType(DailyChallengeScreen), findsOneWidget);
    });
  });
}
