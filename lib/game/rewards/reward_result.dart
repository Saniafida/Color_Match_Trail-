enum RewardResultStatus {
  success,
  partial,
  failed,
  alreadyClaimed
}

class RewardResult {
  final RewardResultStatus status;
  final String? message;

  const RewardResult({
    required this.status,
    this.message,
  });

  bool get isSuccess => status == RewardResultStatus.success || status == RewardResultStatus.partial;
}
