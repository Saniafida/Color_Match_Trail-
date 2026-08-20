import 'security_event_logger.dart';

/// Validates inventory quantities.
class InventoryValidator {
  final SecurityEventLogger _logger;

  // Sane cap for boosters
  static const int maxSaneBoosters = 999;

  InventoryValidator(this._logger);

  /// Returns a safely clamped inventory map.
  Map<String, dynamic> validateBoosterInventory(Map<String, dynamic> inventory) {
    final safeInventory = <String, dynamic>{};
    
    inventory.forEach((key, value) {
      if (value is num) {
        int qty = value.toInt();
        if (qty < 0) {
          _logger.logSaveCorruption('Negative booster qty for $key');
          qty = 0;
        } else if (qty > maxSaneBoosters) {
          _logger.logSaveCorruption('Impossible booster qty for $key');
          qty = maxSaneBoosters;
        }
        safeInventory[key] = qty;
      }
    });

    return safeInventory;
  }
}
