class AnalyticsError {
  final String type;
  final String safeMessage;
  final String module;
  final DateTime timestamp;

  AnalyticsError({
    required this.type,
    required this.safeMessage,
    required this.module,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'safeMessage': safeMessage,
      'module': module,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
