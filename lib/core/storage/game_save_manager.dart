import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'player_save_data.dart';
import 'save_version.dart';
import 'save_result.dart';
import 'save_validator.dart';
import 'save_migration_manager.dart';
import '../security/save_backup_manager.dart';
import '../security/save_integrity_manager.dart';

class GameSaveManager extends ChangeNotifier {
  final SaveBackupManager backupManager;
  final SaveIntegrityManager integrityManager;
  
  PlayerSaveData _playerData = const PlayerSaveData(saveVersion: currentSaveVersion);
  SaveResultStatus _status = SaveResultStatus.idle;
  
  Timer? _debounceTimer;

  GameSaveManager({
    required this.backupManager,
    required this.integrityManager,
  });

  PlayerSaveData get playerData => _playerData;
  SaveResultStatus get status => _status;

  Future<void> initialize() async {
    _status = SaveResultStatus.saving;
    notifyListeners();

    try {
      final primaryRaw = await backupManager.readPrimary();
      if (primaryRaw != null && primaryRaw.isNotEmpty) {
        // Attempt load verifies HMAC hash and extracts payload
        if (!await _attemptLoad(primaryRaw)) {
          // Fallback to backup
          await _attemptRecovery();
        }
      } else {
        // No save found -> Defaults
        _playerData = const PlayerSaveData(
          saveVersion: currentSaveVersion,
          campaignProgress: {'highestUnlockedLevel': 1},
          coins: 100, // Safe default starting coins
        );
        await saveNow();
      }
    } catch (e) {
      await _attemptRecovery();
    }

    _status = SaveResultStatus.idle;
    notifyListeners();
  }

  Future<bool> _attemptLoad(String packagedJson) async {
    try {
      // 1. Verify and extract
      final rawJson = integrityManager.extractAndVerify(packagedJson);
      
      // 2. Decode JSON
      final json = jsonDecode(rawJson);
      
      // 3. Object Mapping
      PlayerSaveData rawData = PlayerSaveData.fromJson(json);
      
      // 4. Migrations
      rawData = SaveMigrationManager.migrate(rawData);
      
      // 5. Hard validation (Legacy internal checks, will be superseded by SecurityManager later)
      _playerData = SaveValidator.validateAndCorrect(rawData);
      
      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to parse primary save: $e');
      return false;
    }
  }

  Future<void> _attemptRecovery() async {
    try {
      final backupRaw = await backupManager.readBackup();
      if (backupRaw != null && backupRaw.isNotEmpty && await _attemptLoad(backupRaw)) {
        if (kDebugMode) print('Recovered from backup save.');
        return;
      }
    } catch (e) {
      if (kDebugMode) print('Failed to parse backup save: $e');
    }
    // Absolute fallback
    _playerData = const PlayerSaveData(saveVersion: currentSaveVersion);
    await saveNow();
  }

  /// Request a save. It will be debounced by 2 seconds.
  void requestSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      saveNow();
    });
  }

  /// Save immediately (bypassing debounce)
  Future<void> saveNow() async {
    _debounceTimer?.cancel();
    _status = SaveResultStatus.saving;
    notifyListeners();

    try {
      // 1. Prepare and validate data
      final safeData = SaveValidator.validateAndCorrect(_playerData);
      final rawJsonString = jsonEncode(safeData.toJson());
      
      // 2. Hash and package
      final packagedJson = integrityManager.packageSaveData(rawJsonString);
      
      // 3. Write via backup manager (automatically rotates backups safely)
      await backupManager.writePrimary(packagedJson);
      
      _status = SaveResultStatus.saved;
    } catch (e) {
      _status = SaveResultStatus.failed;
    }
    
    notifyListeners();
  }

  void updateCampaignProgress(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(campaignProgress: data);
    requestSave();
  }

  void updateFullData(PlayerSaveData data) {
    _playerData = data;
    requestSave();
  }

  void updateCoins(int coins) {
    _playerData = _playerData.copyWith(coins: coins);
    requestSave();
  }

  void updateBoosterInventory(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(boosterInventory: data);
    requestSave();
  }

  void updateSettings(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(settings: data);
    requestSave();
  }

  void updateDailyChallenge(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(dailyChallengeState: data);
    requestSave();
  }

  void updateEventProgress(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(eventProgress: data);
    requestSave();
  }

  void updateStatistics(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(statistics: data);
    requestSave();
  }

  void updateAchievements(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(achievements: data);
    requestSave();
  }

  void updateMilestones(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(milestones: data);
    requestSave();
  }

  void updateOnboarding(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(onboarding: data);
    requestSave();
  }

  void updateScheduledNotifications(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(scheduledNotifications: data);
    requestSave();
  }

  void updateMonetization(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(monetization: data);
    requestSave();
  }

  void updateAnalytics(Map<String, dynamic> data) {
    _playerData = _playerData.copyWith(analytics: data);
    requestSave();
  }

  Future<void> resetAllPlayerData() async {
    await backupManager.clearAll();
    _playerData = const PlayerSaveData(
      saveVersion: currentSaveVersion,
      campaignProgress: {'highestUnlockedLevel': 1},
      coins: 100,
      achievements: {},
      milestones: {},
      statistics: {},
      onboarding: {},
      scheduledNotifications: {},
      monetization: {},
      analytics: {},
    );
    await saveNow();
  }
}
