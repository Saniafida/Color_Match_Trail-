enum AdResultStatus {
  loaded,
  shown,
  completed,
  dismissed,
  failed,
  unavailable,
}

class AdResult {
  final AdResultStatus status;
  final String? rewardId;
  final String? message;

  const AdResult({
    required this.status,
    this.rewardId,
    this.message,
  });

  bool get isSuccess => status == AdResultStatus.completed;
}
