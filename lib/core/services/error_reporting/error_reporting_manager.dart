import 'package:flutter/foundation.dart';
import 'app_error.dart';
import 'error_category.dart';
import 'error_severity.dart';
import 'error_fingerprint.dart';
import 'error_reporting_service.dart';
import '../analytics/analytics_manager.dart';
import '../../performance/performance_logger.dart';

class ErrorReportingManager {
  final ErrorReportingService? reportingProvider;
  final AnalyticsManager? analyticsManager;
  final PerformanceLogger _logger = PerformanceLogger();

  final Map<String, int> _errorCounts = {};
  static const int _maxDuplicateReports = 5;

  String? _lastKnownRoute;
  String? get lastKnownRoute => _lastKnownRoute;

  ErrorReportingManager({
    this.reportingProvider,
    this.analyticsManager,
  });

  Future<void> initialize() async {
    try {
      await reportingProvider?.initialize();
    } catch (e) {
      _logger.logWarning('Failed to initialize ErrorReportingProvider: $e');
    }
  }

  void updateLastKnownRoute(String? routeName) {
    if (routeName != null) {
      _lastKnownRoute = routeName;
    }
  }

  Future<void> reportException(
    dynamic exception,
    StackTrace? stackTrace, {
    ErrorCategory category = ErrorCategory.unknown,
    ErrorSeverity severity = ErrorSeverity.nonFatal,
    String? module,
    Map<String, dynamic>? extraContext,
  }) async {
    final type = exception.runtimeType.toString();
    final message = exception.toString();
    final safeModule = module ?? 'unknown';

    final fingerprint = ErrorFingerprint.generate(type, message, safeModule);
    final count = (_errorCounts[fingerprint.hash] ?? 0) + 1;
    _errorCounts[fingerprint.hash] = count;

    if (count > _maxDuplicateReports) {
      _logger.logWarning('Suppressing duplicate error report: $type in $safeModule');
      return;
    }

    final context = {
      ...?extraContext,
      'lastRoute': _lastKnownRoute,
      'duplicateCount': count,
    };

    final error = AppError(
      type: type,
      message: message,
      stackTrace: stackTrace,
      category: category,
      severity: severity,
      fatal: severity == ErrorSeverity.fatal,
      context: context,
    );

    if (kDebugMode) {
      _logger.logWarning('[ERROR] [${category.name}] [${severity.name}] $type: $message\n$stackTrace');
    }

    try {
      await reportingProvider?.reportError(error);
    } catch (e) {
      _logger.logWarning('ErrorReportingProvider failed to report error: $e');
    }

    // Only forward non-fatal / non-sensitive stats to analytics
    if (!kDebugMode && severity != ErrorSeverity.fatal && analyticsManager != null) {
      try {
        await analyticsManager!.logEvent('error_occurred', parameters: {
          'module': safeModule,
          'severity': severity.name,
          'errorType': type,
          'category': category.name,
        });
      } catch (e) {
        _logger.logWarning('AnalyticsManager failed to report error: $e');
      }
    }
  }

  Future<void> recordLog(String message) async {
    if (kDebugMode) {
      _logger.logEvent(message);
    }
    try {
      await reportingProvider?.recordLog(message);
    } catch (e) {
      // Ignore
    }
  }
}
