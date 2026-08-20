import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../core/storage/game_save_manager.dart';
import 'player_statistics.dart';

class StatisticsManager extends ChangeNotifier with WidgetsBindingObserver {
  final GameSaveManager saveManager;

  PlayerStatistics _stats = const PlayerStatistics();
  Timer? _playtimeTimer;
  bool _isActive = false;

  StatisticsManager({required this.saveManager}) {
    WidgetsBinding.instance.addObserver(this);
  }

  void initialize() {
    _loadStats();
    _startPlaytimeTracking();
  }

  @override
  void dispose() {
    _stopPlaytimeTracking();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPlaytimeTracking();
    } else {
      _stopPlaytimeTracking();
    }
  }

  void _startPlaytimeTracking() {
    if (_isActive) return;
    _isActive = true;
    _playtimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _stats = _stats.copyWith(totalPlayTime: _stats.totalPlayTime + 1);
      if (timer.tick % 60 == 0) { // Save roughly every minute of active play
        _saveStats();
      }
    });
  }

  void _stopPlaytimeTracking() {
    _isActive = false;
    _playtimeTimer?.cancel();
    _playtimeTimer = null;
    _saveStats();
  }

  void _loadStats() {
    final map = saveManager.playerData.statistics;
    try {
      _stats = PlayerStatistics.fromJson(map);
    } catch (_) {
      _stats = const PlayerStatistics();
    }
  }

  void _saveStats() {
    saveManager.updateStatistics(_stats.toJson());
    notifyListeners();
  }

  PlayerStatistics get stats => _stats;

  // --- External Event Hooks ---

  void onLevelCompleted(int stars, int score) {
    _stats = _stats.copyWith(
      levelsCompleted: _stats.levelsCompleted + 1,
      totalStars: _stats.totalStars + stars,
      highestScore: score > _stats.highestScore ? score : _stats.highestScore,
    );
    _saveStats();
  }

  void onBlocksCleared(int count) {
    _stats = _stats.copyWith(totalBlocksCleared: _stats.totalBlocksCleared + count);
    _saveStats();
  }

  void onComboAchieved(int combo) {
    if (combo > _stats.highestCombo) {
      _stats = _stats.copyWith(highestCombo: combo);
      _saveStats();
    }
  }

  void onCascadeAchieved(int cascade) {
    if (cascade > _stats.highestCascade) {
      _stats = _stats.copyWith(highestCascade: cascade);
      _saveStats();
    }
  }

  void onBoosterUsed() {
    _stats = _stats.copyWith(totalBoostersUsed: _stats.totalBoostersUsed + 1);
    _saveStats();
  }

  void onDailyChallengeCompleted() {
    _stats = _stats.copyWith(totalDailyChallenges: _stats.totalDailyChallenges + 1);
    _saveStats();
  }

  void onEventCompleted() {
    _stats = _stats.copyWith(totalEventsCompleted: _stats.totalEventsCompleted + 1);
    _saveStats();
  }
}
