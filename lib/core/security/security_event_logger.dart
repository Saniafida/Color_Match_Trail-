import '../services/analytics/analytics_manager.dart';

/// Safely logs security anomalies without exposing sensitive PII.
class SecurityEventLogger {
  final AnalyticsManager _analyticsManager;

  SecurityEventLogger(this._analyticsManager);

  void logSaveCorruption(String reason) {
    _analyticsManager.logEvent(
      'invalid_save_detected', 
      parameters: {'reason': reason},
    );
  }

  void logDuplicateTransaction(String transactionId) {
    _analyticsManager.logEvent(
      'duplicate_transaction_detected',
      // DO NOT log the full payload, only the event type and an anonymized or safe ID
      parameters: {'id_hash': transactionId.hashCode.toString()},
    );
  }

  void logClockAnomaly(int expectedTime, int actualTime) {
    _analyticsManager.logEvent(
      'clock_anomaly_detected',
      parameters: {'delta': actualTime - expectedTime},
    );
  }

  void logProgressionAnomaly(String details) {
    _analyticsManager.logEvent(
      'invalid_progression_detected',
      parameters: {'details': details},
    );
  }

  void logCurrencyAnomaly(String currency, int amount) {
    _analyticsManager.logEvent(
      'invalid_currency_detected',
      parameters: {'currency': currency}, // Do not log exact manipulated amounts
    );
  }
}
