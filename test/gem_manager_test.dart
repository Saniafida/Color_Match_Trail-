import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/game/gems/gem_manager.dart';
import 'package:color_match_trail/core/storage/shared_preferences_storage.dart';
import 'package:color_match_trail/game/level_result/level_result_system.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/levels/board_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GemManager & 1 Gem Reward on Level Completion Tests', () {
    late SharedPreferencesGameStorage storage;
    late GemManager gemManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = SharedPreferencesGameStorage();
      await storage.init();
      gemManager = GemManager(storage: storage);
      await gemManager.initialize();
    });

    test('1. GemManager initializes with 0 balance and allows adding and spending gems', () async {
      expect(gemManager.balance, 0);

      await gemManager.addGems(1);
      expect(gemManager.balance, 1);

      await gemManager.addGems(5);
      expect(gemManager.balance, 6);

      final spent = await gemManager.spendGems(2);
      expect(spent, isTrue);
      expect(gemManager.balance, 4);

      final overspend = await gemManager.spendGems(10);
      expect(overspend, isFalse);
      expect(gemManager.balance, 4);
    });

    test('2. ServiceLocator level completion awards 1 Gem to player balance', () async {
      SharedPreferences.setMockInitialValues({});
      await ServiceLocator.instance.initialize();

      final initialGems = ServiceLocator.instance.gemManager.balance;

      final resultManager = ServiceLocator.instance.levelResultManager;

      // Simulate level complete event
      final finalResult = FinalLevelResult(
        status: GameStatus.won,
        reason: LevelResultReason.goalsCompleted,
        finalScore: 10000,
        remainingMoves: 5,
        remainingTime: 0,
        completedGoals: [],
        incompleteGoals: [],
      );

      await resultManager.processResult(
        event: LevelResultEvent(finalResult),
        levelData: const LevelDefinition(
          id: 1,
          boardConfig: BoardConfig(rows: 7, columns: 7),
          movesLimit: 20,
        ),
        highestCombo: 3,
        largestBlast: 6,
      );

      expect(ServiceLocator.instance.gemManager.balance, initialGems + 1);
    });
  });
}
