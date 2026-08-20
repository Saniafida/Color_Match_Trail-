enum SaveResultStatus {
  idle,
  saving,
  saved,
  failed,
}

class SaveResult {
  final SaveResultStatus status;
  final String? error;

  const SaveResult({
    required this.status,
    this.error,
  });

  bool get isSuccess => status == SaveResultStatus.saved;
}
