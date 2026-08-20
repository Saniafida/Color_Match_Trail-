import 'package:uuid/uuid.dart';
import 'error_severity.dart';
import 'error_category.dart';

class AppError {
  final String errorId;
  final String type;
  final String message;
  final StackTrace? stackTrace;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final bool fatal;
  final Map<String, dynamic> context;

  AppError({
    String? errorId,
    required this.type,
    required this.message,
    this.stackTrace,
    this.category = ErrorCategory.unknown,
    this.severity = ErrorSeverity.nonFatal,
    DateTime? timestamp,
    this.fatal = false,
    Map<String, dynamic>? context,
  })  : errorId = errorId ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        context = context ?? {};

  Map<String, dynamic> toMap() {
    return {
      'errorId': errorId,
      'type': type,
      'message': message,
      'category': category.name,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'fatal': fatal,
      'context': context,
    };
  }
}
