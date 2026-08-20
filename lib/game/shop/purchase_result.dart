enum PurchaseResultStatus {
  success,
  insufficientFunds,
  inventoryFull,
  error,
}

class PurchaseResult {
  final PurchaseResultStatus status;
  final String? message;

  const PurchaseResult({
    required this.status,
    this.message,
  });

  bool get isSuccess => status == PurchaseResultStatus.success;
}
