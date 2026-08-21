import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/progression/progression_manager.dart';
import 'package:color_match_trail/game/rewards/reward_manager.dart';
import 'package:color_match_trail/game/rewards/reward_claim_store.dart';
import 'package:color_match_trail/game/coins/coin_manager.dart';
import 'package:color_match_trail/game/inventory/inventory_manager.dart';
import 'package:color_match_trail/core/storage/game_save_manager.dart';
import 'package:color_match_trail/core/storage/game_save_manager_storage.dart';
import 'package:color_match_trail/core/data/game_data_manager.dart';
import 'package:color_match_trail/core/services/error_reporting/error_reporting_manager.dart';
import 'package:color_match_trail/core/services/analytics/analytics_manager.dart';
import 'package:color_match_trail/core/services/analytics/analytics_service.dart';
import 'package:color_match_trail/core/services/analytics/analytics_config.dart';
import 'package:color_match_trail/core/security/security_config.dart';
import 'package:color_match_trail/core/security/save_backup_manager.dart';
import 'package:color_match_trail/core/security/save_integrity_manager.dart';
import 'package:color_match_trail/game/achievements/achievement_manager.dart';
import 'package:color_match_trail/game/achievements/achievement_storage.dart';
import 'package:color_match_trail/game/achievements/milestone_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameSaveManager saveManager;
  late GameDataManager dataManager;
  late RewardManager rewardManager;
  late ProgressionManager progressionManager;
  late AchievementManager achievementManager;
  late MilestoneManager milestoneManager;
  late CoinManager coinManager;

  setUp(() async {
    final securityConfig = const SecurityConfig();
    final integrityManager = SaveIntegrityManager(securityConfig);
    final backupManager = SaveBackupManager();

    saveManager = GameSaveManager(
      backupManager: backupManager,
      integrityManager: integrityManager,
    );
    await saveManager.initialize();

    final storage = GameSaveManagerStorage(saveManager: saveManager);
    await storage.init();

    final analyticsManager = AnalyticsManager(
      service: StubAnalyticsService(),
      saveManager: saveManager,
      config: AnalyticsConfig.development(),
    );
    final errorManager = ErrorReportingManager(analyticsManager: analyticsManager);

    dataManager = GameDataManager(errorReportingManager: errorManager);
    await dataManager.initialize();

    coinManager = CoinManager(storage: storage);
    await coinManager.initialize();

    final inventoryManager = InventoryManager(storage: storage);
    await inventoryManager.initialize();

    final claimStore = RewardClaimStore(saveManager: saveManager);
    rewardManager = RewardManager(
      coinManager: coinManager,
      inventoryManager: inventoryManager,
      claimStore: claimStore,
    );

    achievementManager = AchievementManager(
      storage: AchievementStorage(saveManager: saveManager),
      rewardManager: rewardManager,
    );
    await achievementManager.initialize([]);

    milestoneManager = MilestoneManager(
      saveManager: saveManager,
      rewardManager: rewardManager,
    );

    progressionManager = ProgressionManager(
      saveManager: saveManager,
      dataManager: dataManager,
      rewardManager: rewardManager,
      achievementManager: achievementManager,
      milestoneManager: milestoneManager,
    );
    progressionManager.initialize();
  });

  group('Module 54 Progression System Tests', () {
    test('1. Level 1 starts unlocked', () {
      expect(progressionManager.canPlayLevel('level_1'), isTrue);
    });

    test('2. Level 2 unlocks after Level 1 completion', () async {
      expect(progressionManager.canPlayLevel('level_2'), isFalse);

      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 1500,
        stars: 3,
        movesUsed: 12,
        highestCombo: 2,
        completed: true,
      );

      expect(progressionManager.canPlayLevel('level_2'), isTrue);
      expect(progressionManager.state.levels['level_1']?.completed, isTrue);
    });

    test('3. Locked level cannot start', () {
      final validation = progressionManager.validateLevelAccess('level_5');
      expect(validation.isUnlocked, isFalse);
    });

    test('4. Level completion saves properly', () async {
      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 1800,
        stars: 2,
        movesUsed: 15,
        highestCombo: 3,
        completed: true,
      );

      final progress = progressionManager.state.levels['level_1'];
      expect(progress, isNotNull);
      expect(progress!.completed, isTrue);
      expect(progress.bestScore, 1800);
      expect(progress.bestStars, 2);
    });

    test('5. Replay score preserves highest (never downgrades)', () async {
      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 5000,
        stars: 2,
        movesUsed: 15,
        highestCombo: 3,
        completed: true,
      );

      // Replay with lower score
      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 3000,
        stars: 1,
        movesUsed: 18,
        highestCombo: 2,
        completed: true,
      );

      final progress = progressionManager.state.levels['level_1']!;
      expect(progress.bestScore, 5000);
      expect(progress.bestStars, 2);

      // Replay with higher score
      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 7000,
        stars: 3,
        movesUsed: 10,
        highestCombo: 4,
        completed: true,
      );

      final updated = progressionManager.state.levels['level_1']!;
      expect(updated.bestScore, 7000);
      expect(updated.bestStars, 3);
    });

    test('6. Completed levels remain replayable', () async {
      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 2000,
        stars: 3,
        movesUsed: 10,
        highestCombo: 3,
        completed: true,
      );

      expect(progressionManager.canPlayLevel('level_1'), isTrue);
      expect(progressionManager.validateLevelAccess('level_1').isUnlocked, isTrue);
    });

    test('7. World progress updates properly', () async {
      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 2000,
        stars: 3,
        movesUsed: 10,
        highestCombo: 3,
        completed: true,
      );

      final wp = progressionManager.getWorldProgress('world_1');
      expect(wp.completedLevels, 1);
      expect(wp.stars, 3);
      expect(wp.completionPercentage, closeTo(0.2, 0.01));
    });

    test('8. First win reward is granted only once', () async {
      final initialCoins = coinManager.balance;

      // First win
      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 2000,
        stars: 3,
        movesUsed: 10,
        highestCombo: 3,
        completed: true,
      );

      expect(coinManager.balance, greaterThan(initialCoins));
      final coinsAfterFirstWin = coinManager.balance;

      // Replay win
      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 3000,
        stars: 3,
        movesUsed: 8,
        highestCombo: 4,
        completed: true,
      );

      // Coins should not increase again for the same level
      expect(coinManager.balance, equals(coinsAfterFirstWin));
    });

    test('9. Home Continue returns next playable level', () async {
      expect(progressionManager.getNextPlayableLevel(), 'level_1');

      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 2000,
        stars: 3,
        movesUsed: 10,
        highestCombo: 3,
        completed: true,
      );

      expect(progressionManager.getNextPlayableLevel(), 'level_2');
    });

    test('10. Full reset clears progression to initial valid state', () {
      progressionManager.resetProgression();
      expect(progressionManager.state.levels['level_1']?.unlocked, isTrue);
      expect(progressionManager.state.levels['level_1']?.completed, isFalse);
    });
  });
}
