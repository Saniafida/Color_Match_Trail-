import 'security_event_logger.dart';

/// Validates reward grants.
class RewardValidator {
  final SecurityEventLogger _logger;

  RewardValidator(this._logger);

  /// Validates that a requested reward matches valid game configurations.
  bool isValidReward(String rewardId, int amount) {
    if (amount <= 0) {
      _logger.logSaveCorruption('Attempted to grant invalid reward amount: $amount');
      return false;
    }

    // In a fully data-driven setup, this would cross-reference GameDataManager
    // to verify if `rewardId` exists and the amount is within allowed bounds.
    // For now, we do a basic bounds check.
    if (amount > 10000) { 
      _logger.logSaveCorruption('Suspiciously large reward amount requested: $amount');
      return false; // Very suspicious, block it
    }

    return true;
  }
}
