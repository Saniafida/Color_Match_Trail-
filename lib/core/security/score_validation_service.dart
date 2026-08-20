import 'security_event_logger.dart';

/// Service prepared for future server-side competitive validation.
/// Currently performs basic client-side plausibility checks.
class ScoreValidationService {
  final SecurityEventLogger _logger;

  ScoreValidationService(this._logger);

  /// Validates if a score increment is mathematically possible in one move.
  bool isValidScoreIncrement(int increment) {
    if (increment < 0) return false;
    
    // An absolutely massive single-move increment is mathematically impossible 
    // on a standard board. (e.g. 1 million points in one swipe)
    if (increment > 50000) {
      _logger.logSaveCorruption('Impossible score increment detected: $increment');
      return false;
    }
    return true;
  }

  /// Validates a final level score before submitting to leaderboards.
  bool isValidFinalScore(int finalScore) {
    if (finalScore < 0) return false;
    if (finalScore > 5000000) {
      _logger.logSaveCorruption('Impossible final score detected: $finalScore');
      return false;
    }
    return true;
  }
}
