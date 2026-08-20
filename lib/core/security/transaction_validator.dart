import 'security_event_logger.dart';

/// Prevents processing the same transaction multiple times (duplicate rewards).
class TransactionValidator {
  final SecurityEventLogger _logger;
  
  // In a real app, this should be persisted to disk so it survives app restarts.
  // For this implementation, we use an in-memory rotating buffer.
  final List<String> _processedTransactions = [];
  static const int _maxBufferSize = 100;

  TransactionValidator(this._logger);

  /// Checks if a transaction is unique and registers it.
  /// Returns true if it is safe to proceed. Returns false if duplicate.
  bool registerAndValidate(String transactionId) {
    if (_processedTransactions.contains(transactionId)) {
      _logger.logDuplicateTransaction(transactionId);
      return false; // Duplicate detected
    }

    _processedTransactions.add(transactionId);
    if (_processedTransactions.length > _maxBufferSize) {
      _processedTransactions.removeAt(0); // Keep buffer bounded
    }
    return true;
  }
}
