import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/date_service.dart';

class LivesManager extends ChangeNotifier {
  static const int maxLives = 5;
  static const String _keyLives = 'player_daily_lives_count';
  static const String _keyLastRefillDate = 'player_lives_last_refill_date';
  static const int refillCostInCoins = 200;

  final DateService _dateService;
  int _lives = maxLives;
  String _lastRefillDate = '';

  LivesManager({DateService? dateService}) : _dateService = dateService ?? DateService();

  int get lives => _lives;
  int get maximumLives => maxLives;
  bool get hasLives => _lives > 0;
  bool get isFull => _lives >= maxLives;
  String get lastRefillDate => _lastRefillDate;

  String get label => _lives >= maxLives ? '5 Full' : '$_lives/$maxLives';

  Future<void> initialize() async {
    final today = _getTodayString();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_keyLastRefillDate);
      final savedLives = prefs.getInt(_keyLives);

      if (savedDate == null || savedDate != today) {
        // Daily Refill! New calendar day gives fresh 5 lives
        _lives = maxLives;
        _lastRefillDate = today;
        await prefs.setInt(_keyLives, _lives);
        await prefs.setString(_keyLastRefillDate, _lastRefillDate);
      } else {
        _lives = (savedLives ?? maxLives).clamp(0, maxLives);
        _lastRefillDate = savedDate;
      }
    } catch (_) {
      _lives = maxLives;
      _lastRefillDate = today;
    }
    notifyListeners();
  }

  String _getTodayString() {
    final now = _dateService.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Checks if day has changed and refills to 5 lives if so
  Future<void> checkDailyRefill() async {
    final today = _getTodayString();
    if (_lastRefillDate != today) {
      _lives = maxLives;
      _lastRefillDate = today;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyLives, _lives);
        await prefs.setString(_keyLastRefillDate, _lastRefillDate);
      } catch (_) {}
      notifyListeners();
    }
  }

  /// Deducts 1 life when a player gets out / fails a level
  Future<bool> consumeLife() async {
    await checkDailyRefill();
    if (_lives > 0) {
      _lives--;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyLives, _lives);
        await prefs.setString(_keyLastRefillDate, _lastRefillDate);
      } catch (_) {}
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Refills lives to full (5) or by specified count
  Future<void> refillLives([int count = maxLives]) async {
    _lives = (_lives + count).clamp(0, maxLives);
    _lastRefillDate = _getTodayString();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLives, _lives);
      await prefs.setString(_keyLastRefillDate, _lastRefillDate);
    } catch (_) {}
    notifyListeners();
  }

  /// Refill with coins (costs 200 coins)
  Future<bool> refillWithCoins(dynamic coinManager) async {
    if (coinManager.balance >= refillCostInCoins) {
      final success = await coinManager.spendCoins(refillCostInCoins);
      if (success) {
        await refillLives(maxLives);
        return true;
      }
    }
    return false;
  }

  /// Reset / Override for unit tests
  void setLivesForTesting(int count, {String? date}) {
    _lives = count.clamp(0, maxLives);
    if (date != null) _lastRefillDate = date;
    notifyListeners();
  }
}
