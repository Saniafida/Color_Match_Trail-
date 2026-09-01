import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_match_trail/game/lives/lives_manager.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/game/level_result/game_status.dart';
import 'package:color_match_trail/game/level_result/level_result.dart';
import 'package:color_match_trail/game/level_result/level_result_reason.dart';
import 'package:color_match_trail/game/level_result/level_event.dart';
import 'package:color_match_trail/game/levels/board_config.dart';
import 'package:color_match_trail/models/level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.instance.initialize();
  });

  group('Daily 5 Lives & Loss Deduction System Tests', () {
    late LivesManager livesManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      livesManager = ServiceLocator.instance.livesManager;
      await livesManager.initialize();
      await livesManager.refillLives(5);
    });

    test('1. Initial state gives player exactly 5 full lives', () {
      expect(livesManager.lives, 5);
      expect(livesManager.hasLives, isTrue);
      expect(livesManager.isFull, isTrue);
      expect(livesManager.label, '5 Full');
    });

    test('2. Failing a level deducts exactly 1 life', () async {
      expect(livesManager.lives, 5);

      final consumed = await livesManager.consumeLife();
      expect(consumed, isTrue);
      expect(livesManager.lives, 4);
      expect(livesManager.label, '4/5');

      await livesManager.consumeLife();
      expect(livesManager.lives, 3);
      expect(livesManager.label, '3/5');
    });

    test('3. Lives cannot drop below 0 and consumeLife returns false at 0', () async {
      livesManager.setLivesForTesting(1);
      expect(livesManager.lives, 1);

      final c1 = await livesManager.consumeLife();
      expect(c1, isTrue);
      expect(livesManager.lives, 0);
      expect(livesManager.hasLives, isFalse);
      expect(livesManager.label, '0/5');

      final c2 = await livesManager.consumeLife();
      expect(c2, isFalse);
      expect(livesManager.lives, 0);
    });

    test('4. On the next day, lives automatically refill to 5 full lives', () async {
      // Simulate yesterday with 1 life left
      livesManager.setLivesForTesting(1, date: '2026-08-31');
      expect(livesManager.lives, 1);

      // Trigger daily check for today
      await livesManager.checkDailyRefill();

      expect(livesManager.lives, 5);
      expect(livesManager.isFull, isTrue);
      expect(livesManager.label, '5 Full');
    });

    test('5. LevelResultManager automatically consumes 1 life on level loss', () async {
      livesManager.setLivesForTesting(5);
      expect(livesManager.lives, 5);

      final resultManager = ServiceLocator.instance.levelResultManager;
      final failedEvent = LevelResultEvent(
        const FinalLevelResult(
          status: GameStatus.lost,
          reason: LevelResultReason.movesExhausted,
          finalScore: 500,
          remainingMoves: 0,
          remainingTime: 0,
          completedGoals: [],
        ),
      );

      const levelDef = LevelDefinition(
        id: 1,
        boardConfig: BoardConfig(rows: 6, columns: 6),
        movesLimit: 15,
        goals: [],
      );

      await resultManager.processResult(
        event: failedEvent,
        levelData: levelDef,
        highestCombo: 0,
        largestBlast: 0,
      );

      expect(livesManager.lives, 4);
      expect(resultManager.currentResult?.completed, isFalse);
    });

    test('6. Refill with coins adds 5 full lives when player has enough coins', () async {
      livesManager.setLivesForTesting(0);
      expect(livesManager.hasLives, isFalse);

      final coinManager = ServiceLocator.instance.coinManager;
      await coinManager.addCoins(500);

      final success = await livesManager.refillWithCoins(coinManager);
      expect(success, isTrue);
      expect(livesManager.lives, 5);
      expect(livesManager.isFull, isTrue);
    });
  });
}
