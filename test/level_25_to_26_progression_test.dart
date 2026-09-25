import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/core/data/game_data_manager.dart';
import 'package:color_match_trail/core/services/error_reporting/error_reporting_manager.dart';
import 'package:color_match_trail/core/storage/game_save_manager.dart';
import 'package:color_match_trail/core/security/save_backup_manager.dart';
import 'package:color_match_trail/core/security/save_integrity_manager.dart';
import 'package:color_match_trail/core/security/security_config.dart';
import 'package:color_match_trail/game/progression/progression_manager.dart';
import 'package:color_match_trail/game/progression/progression_state.dart';
import 'package:color_match_trail/game/progression/level_progress.dart';
import 'package:color_match_trail/game/progression/progression_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Level 25 to Level 26 Continuous Progression Tests', () {
    test('GameDataManager loads all 15 worlds covering levels 1 to 147 without gaps', () async {
      final dataManager = GameDataManager(errorReportingManager: ErrorReportingManager());
      await dataManager.initialize();

      final worlds = dataManager.getAllWorlds();
      expect(worlds.length, equals(15));

      final allLevelIds = <String>[];
      for (final w in worlds) {
        allLevelIds.addAll(w.levelIds);
      }

      expect(allLevelIds.length, equals(147));
      for (int i = 1; i <= 147; i++) {
        expect(allLevelIds[i - 1], equals('level_$i'),
            reason: 'Level sequence must be strictly continuous at index ${i - 1}');
      }

      // Check World 3 specifically contains level_25 AND level_26
      final world3 = worlds.firstWhere((w) => w.worldId == 'world_3');
      expect(world3.levelIds.contains('level_25'), isTrue);
      expect(world3.levelIds.contains('level_26'), isTrue);
      expect(world3.levelIds.indexOf('level_26'), equals(world3.levelIds.indexOf('level_25') + 1));
    });

    test('Completing level 25 unlocks level 26 (never skips to level 51)', () async {
      final dataManager = GameDataManager(errorReportingManager: ErrorReportingManager());
      await dataManager.initialize();

      final securityConfig = const SecurityConfig();
      final integrityManager = SaveIntegrityManager(securityConfig);
      final backupManager = SaveBackupManager();

      final saveManager = GameSaveManager(
        backupManager: backupManager,
        integrityManager: integrityManager,
      );
      await saveManager.initialize();

      final progressionManager = ProgressionManager(
        saveManager: saveManager,
        dataManager: dataManager,
      );
      progressionManager.initialize();

      // Complete levels 1 through 24
      for (int i = 1; i <= 24; i++) {
        await progressionManager.saveLevelResult(
          levelId: 'level_$i',
          score: 1000 + i * 100,
          stars: 3,
          movesUsed: 10,
          highestCombo: 3,
          completed: true,
        );
      }

      // Now complete level 25
      await progressionManager.saveLevelResult(
        levelId: 'level_25',
        score: 5000,
        stars: 3,
        movesUsed: 12,
        highestCombo: 4,
        completed: true,
      );

      // Verify level 26 is unlocked and currentLevel is level_26
      expect(progressionManager.state.levels['level_26']?.unlocked, isTrue,
          reason: 'Level 26 must be unlocked after Level 25');
      expect(progressionManager.getNextPlayableLevel(), equals('level_26'));
      expect(progressionManager.state.currentLevel, equals('level_26'));

      // Level 51 must NOT be unlocked
      expect(progressionManager.state.levels['level_51']?.unlocked ?? false, isFalse,
          reason: 'Level 51 must not be unlocked after Level 25');
    });

    test('ProgressionValidator repairs corrupted state where level 51 was unlocked after level 25', () async {
      final dataManager = GameDataManager(errorReportingManager: ErrorReportingManager());
      await dataManager.initialize();

      // Simulate corrupted state: levels 1-25 completed, level 51 erroneously unlocked and currentLevel = level_51
      final levels = <String, LevelProgress>{};
      for (int i = 1; i <= 25; i++) {
        levels['level_$i'] = LevelProgress(
          levelId: 'level_$i',
          unlocked: true,
          completed: true,
          bestStars: 3,
          bestScore: 2000,
        );
      }
      // Bug state: level 51 unlocked, level 26 NOT unlocked
      levels['level_51'] = LevelProgress.unlocked('level_51');

      final corruptedState = ProgressionState(
        levels: levels,
        unlockedWorlds: {'world_1', 'world_2', 'world_3', 'world_6'},
        currentLevel: 'level_51',
      );

      final repairedState = ProgressionValidator.validateAndRepair(corruptedState, dataManager);

      // Level 26 must now be unlocked
      expect(repairedState.levels['level_26']?.unlocked, isTrue);
      // Level 51 must be relocked
      expect(repairedState.levels['level_51']?.unlocked, isFalse);
      // Current level must be corrected to level_26
      expect(repairedState.currentLevel, equals('level_26'));
      // World 3 must be unlocked
      expect(repairedState.unlockedWorlds.contains('world_3'), isTrue);
    });
  });
}
