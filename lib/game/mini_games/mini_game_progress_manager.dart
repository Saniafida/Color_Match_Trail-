import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/game_save_manager.dart';
import '../../core/services/service_locator.dart';

/// Manages persistent progress for all mini-games.
/// Uses dual-layer persistence: SharedPreferences for instant local sync
/// and GameSaveManager for tamper-resistant encrypted backups.
class MiniGameProgressManager {
  static final MiniGameProgressManager instance = MiniGameProgressManager._internal();
  MiniGameProgressManager._internal();

  static const String tileSort = 'tile_sort';
  static const String tileStack = 'tile_stack';
  static const String tileDrop = 'tile_drop';
  static const String tileSwap = 'tile_swap';

  static const List<String> allGameKeys = [
    tileSort,
    tileStack,
    tileDrop,
    tileSwap,
  ];

  final Map<String, int> _levels = {
    tileSort: 1,
    tileStack: 1,
    tileDrop: 1,
    tileSwap: 1,
  };

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize and load saved levels from SharedPreferences and GameSaveManager.
  Future<void> initialize({GameSaveManager? saveManager, SharedPreferences? preferences}) async {
    // 1. Load from SharedPreferences
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      for (final key in allGameKeys) {
        final saved = prefs.getInt('minigame_${key}_level');
        if (saved != null && saved > (_levels[key] ?? 1)) {
          _levels[key] = saved;
        }
      }
    } catch (_) {}

    // 2. Load from GameSaveManager
    try {
      final sm = saveManager ?? ServiceLocator.instance.gameSaveManager;
      final savedMap = sm.playerData.miniGameProgress;
      for (final key in allGameKeys) {
        final val = savedMap[key];
        if (val is int && val > (_levels[key] ?? 1)) {
          _levels[key] = val;
        }
      }
    } catch (_) {}

    _isInitialized = true;
  }

  /// Get current level for given mini-game (defaults to 1).
  int getLevel(String gameKey) {
    int level = _levels[gameKey] ?? 1;

    // Check GameSaveManager if available and has newer progress
    try {
      final sm = ServiceLocator.instance.gameSaveManager;
      final savedMap = sm.playerData.miniGameProgress;
      final val = savedMap[gameKey];
      if (val is int && val > level) {
        level = val;
        _levels[gameKey] = level;
      }
    } catch (_) {}

    return level < 1 ? 1 : level;
  }

  /// Save progress when reaching or unlocking a level.
  /// Progress will not be downgraded if a lower level is passed.
  Future<void> saveLevel(String gameKey, int level) async {
    if (level < 1) level = 1;
    final current = _levels[gameKey] ?? 1;
    if (level < current) {
      // Keep higher reached level
      return;
    }

    _levels[gameKey] = level;

    // 1. SharedPreferences (instant local cache)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('minigame_${gameKey}_level', level);
    } catch (_) {}

    // 2. GameSaveManager (encrypted backup + state sync)
    try {
      final sm = ServiceLocator.instance.gameSaveManager;
      final updated = Map<String, dynamic>.from(sm.playerData.miniGameProgress);
      updated[gameKey] = level;
      sm.updateMiniGameProgress(updated);
      await sm.saveNow();
    } catch (_) {}
  }

  /// Reset all mini game levels back to 1.
  Future<void> resetAll() async {
    for (final key in allGameKeys) {
      _levels[key] = 1;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('minigame_${key}_level');
      } catch (_) {}
    }

    try {
      final sm = ServiceLocator.instance.gameSaveManager;
      sm.updateMiniGameProgress({});
      await sm.saveNow();
    } catch (_) {}
  }
}
