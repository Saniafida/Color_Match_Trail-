import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'app/app.dart';
import 'core/services/service_locator.dart';
import 'core/services/error_reporting/error_category.dart';
import 'core/services/error_reporting/error_severity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ServiceLocator.instance.initialize();

  // Hook Flutter Errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    try {
      ServiceLocator.instance.errorReportingManager.reportException(
        details.exception,
        details.stack,
        category: ErrorCategory.unknown,
        severity: ErrorSeverity.nonFatal, // Prevent simple build errors from hard crashing
      );
    } catch (_) {}
  };

  // Hook Async errors not caught by Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      ServiceLocator.instance.errorReportingManager.reportException(
        error,
        stack,
        category: ErrorCategory.unknown,
        severity: ErrorSeverity.nonFatal,
      );
      return true; // Mark as handled
    } catch (_) {
      return false;
    }
  };

  runApp(const ColorMatchTrailApp());
}

