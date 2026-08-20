import 'security_event_logger.dart';

/// Validates currencies to ensure they do not exceed impossible limits or drop below zero.
class CurrencyValidator {
  final SecurityEventLogger _logger;

  // Assuming a max sane cap for standard coins (e.g. 9,999,999)
  static const int maxSaneCoins = 9999999;

  CurrencyValidator(this._logger);

  /// Validates and caps currency. Returns a safe integer.
  int validateCoins(int coins) {
    if (coins < 0) {
      _logger.logCurrencyAnomaly('coins', coins);
      return 0; // Negative coins are impossible, recover to 0
    }
    if (coins > maxSaneCoins) {
      _logger.logCurrencyAnomaly('coins', coins);
      return maxSaneCoins; // Recover to hard cap
    }
    return coins;
  }
}
