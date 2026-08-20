import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../storage/game_save_manager.dart';
import 'analytics_config.dart';
import 'analytics_consent_state.dart';
import 'analytics_debug_logger.dart';
import 'analytics_error.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';

class AnalyticsManager extends ChangeNotifier {
  final AnalyticsService _service;
  final GameSaveManager _saveManager;
  final AnalyticsConfig _config;
  final AnalyticsDebugLogger _debugLogger = AnalyticsDebugLogger();

  bool _initialized = false;
  AnalyticsConsentState _consentState = AnalyticsConsentState.unknown;
  final List<AnalyticsEvent> _offlineQueue = [];

  static const String _consentKey = 'consentState';
  static const String _queueKey = 'offlineQueue';

  AnalyticsManager({
    required AnalyticsService service,
    required GameSaveManager saveManager,
    AnalyticsConfig config = const AnalyticsConfig(),
  })  : _service = service,
        _saveManager = saveManager,
        _config = config;

  AnalyticsConsentState get consentState => _consentState;

  Future<void> initialize() async {
    if (_initialized) return;

    // Load consent and queue from save data
    _loadState();

    // Initialize service
    await _service.initialize(_config);

    // Apply consent to service
    if (_consentState == AnalyticsConsentState.disabled) {
      await _service.setEnabled(false);
    } else {
      await _service.setEnabled(true);
      // We don't wait for the queue to flush before marking initialized
      _flushOfflineQueue();
    }

    _initialized = true;
    notifyListeners();
  }

  void _loadState() {
    final data = _saveManager.playerData.analytics;
    
    // Load consent
    final stateStr = data[_consentKey] as String?;
    _consentState = AnalyticsConsentState.values.firstWhere(
      (e) => e.name == stateStr,
      orElse: () => AnalyticsConsentState.unknown,
    );

    // Load queue
    final queueList = data[_queueKey] as List<dynamic>? ?? [];
    for (final item in queueList) {
      if (item is String) {
        try {
          final jsonMap = jsonDecode(item) as Map<String, dynamic>;
          _offlineQueue.add(AnalyticsEvent.fromJson(jsonMap));
        } catch (_) {
          // Ignore corrupt queue items
        }
      }
    }
  }

  void _saveState() {
    final updated = Map<String, dynamic>.from(_saveManager.playerData.analytics);
    updated[_consentKey] = _consentState.name;
    updated[_queueKey] = _offlineQueue.map((e) => jsonEncode(e.toJson())).toList();
    _saveManager.updateAnalytics(updated);
  }

  Future<void> setConsent(AnalyticsConsentState state) async {
    if (_consentState == state) return;
    
    _consentState = state;
    _saveState();

    if (_consentState == AnalyticsConsentState.disabled) {
      await _service.setEnabled(false);
      _offlineQueue.clear();
      _saveState();
    } else {
      await _service.setEnabled(true);
      _flushOfflineQueue();
    }
    
    notifyListeners();
  }

  Future<void> _flushOfflineQueue() async {
    if (_consentState == AnalyticsConsentState.disabled || _offlineQueue.isEmpty) return;

    final queueCopy = List<AnalyticsEvent>.from(_offlineQueue);
    _offlineQueue.clear();
    _saveState();

    for (final event in queueCopy) {
      try {
        await _service.logEvent(event);
      } catch (e) {
        // If it fails again, we could requeue, but to prevent unbounded growth,
        // we might just drop it for this simple implementation.
        debugPrint('[AnalyticsManager] Failed to flush event: $e');
      }
    }
  }

  // --- Core Tracking Methods ---

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (_consentState == AnalyticsConsentState.disabled) return;

    final event = AnalyticsEvent(name: name, parameters: parameters);

    if (_config.debug) {
      _debugLogger.logEvent(event);
    }

    try {
      await _service.logEvent(event);
    } catch (e) {
      // Add to offline queue on failure
      if (_offlineQueue.length < 100) { // Limit queue size to prevent save bloat
        _offlineQueue.add(event);
        _saveState();
      }
    }
  }

  Future<void> logScreen(String screenName) async {
    if (_consentState == AnalyticsConsentState.disabled) return;

    if (_config.debug) {
      _debugLogger.logScreen(screenName);
    }

    try {
      await _service.logScreenView(screenName);
    } catch (e) {
      debugPrint('[AnalyticsManager] Failed to log screen: $e');
    }
  }

  Future<void> logError(String type, String safeMessage, String module) async {
    if (_consentState == AnalyticsConsentState.disabled) return;

    final error = AnalyticsError(type: type, safeMessage: safeMessage, module: module);

    if (_config.debug) {
      _debugLogger.logError(error);
    }

    try {
      await _service.logError(error);
    } catch (e) {
      debugPrint('[AnalyticsManager] Failed to log error: $e');
    }
  }

  Future<void> setUserProperty(String key, dynamic value) async {
    if (_consentState == AnalyticsConsentState.disabled) return;

    if (_config.debug) {
      _debugLogger.logUserProperty(key, value);
    }

    try {
      await _service.setUserProperty(key, value);
    } catch (e) {
      debugPrint('[AnalyticsManager] Failed to set user property: $e');
    }
  }

  // --- Convenience Tracking Methods for the Game ---

  void trackLevelCompleted({
    required int levelId,
    required int score,
    required int stars,
    required int movesUsed,
    required int remainingMoves,
  }) {
    logEvent('level_completed', parameters: {
      'levelId': levelId,
      'score': score,
      'stars': stars,
      'movesUsed': movesUsed,
      'remainingMoves': remainingMoves,
    });
  }

  void trackLevelFailed({
    required int levelId,
    required int score,
    required int movesUsed,
    required String failReason,
  }) {
    logEvent('level_failed', parameters: {
      'levelId': levelId,
      'score': score,
      'movesUsed': movesUsed,
      'failReason': failReason, // e.g., 'out_of_moves', 'out_of_time'
    });
  }

  void trackGameplayAction(String action, Map<String, dynamic> additionalParams) {
    // Valid actions: 'match_created', 'blast_created', 'cascade_created', etc.
    logEvent(action, parameters: additionalParams);
  }
}
