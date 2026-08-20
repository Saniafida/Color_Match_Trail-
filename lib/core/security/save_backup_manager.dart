import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Manages multiple backup snapshots of save data to recover from corruption.
class SaveBackupManager {
  static const String _primaryKey = 'master_save_data';
  static const String _backup1Key = 'master_save_data_backup_1';
  static const String _backup2Key = 'master_save_data_backup_2';

  /// Reads the primary save data payload.
  Future<String?> readPrimary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_primaryKey);
  }

  /// Attempts to read the most recent valid backup.
  /// Returns the JSON string, or null if no valid backups exist.
  Future<String?> readBackup() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try backup 1
    final b1 = prefs.getString(_backup1Key);
    if (b1 != null && b1.isNotEmpty) return b1;

    // Try backup 2
    final b2 = prefs.getString(_backup2Key);
    if (b2 != null && b2.isNotEmpty) return b2;

    return null;
  }

  /// Writes a new primary save, rotating the previous primary into backup 1,
  /// and the old backup 1 into backup 2.
  Future<void> writePrimary(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    
    final currentPrimary = prefs.getString(_primaryKey);
    final currentB1 = prefs.getString(_backup1Key);

    // Rotate
    if (currentB1 != null && currentB1.isNotEmpty) {
      await prefs.setString(_backup2Key, currentB1);
    }
    
    if (currentPrimary != null && currentPrimary.isNotEmpty) {
      await prefs.setString(_backup1Key, currentPrimary);
    }
    
    // Write new
    await prefs.setString(_primaryKey, jsonString);
    if (kDebugMode) print('Primary save written and backups rotated safely.');
  }

  /// Clears all save data (used for GDPR reset or debugging).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_primaryKey);
    await prefs.remove(_backup1Key);
    await prefs.remove(_backup2Key);
  }
}
