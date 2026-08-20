import 'package:flutter/material.dart';
import '../../../app/routes/routes.dart';
import '../../services/service_locator.dart';
import 'error_category.dart';

class ErrorRecovery {
  /// Defines safe fallback routes based on the error category and current context.
  static void fallbackRoute(BuildContext context, ErrorCategory category) {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    final errorManager = ServiceLocator.instance.errorReportingManager;
    final lastRoute = errorManager.lastKnownRoute;

    // Avoid routing if we're already at the safe destination or if there's no navigator
    if (lastRoute == AppRoutes.home && category != ErrorCategory.save) return;

    switch (category) {
      case ErrorCategory.loading:
      case ErrorCategory.gameplay:
        // Gameplay or level loading failed, fall back to Level Select or Home
        if (lastRoute == AppRoutes.gameplay) {
          navigator.pushReplacementNamed(AppRoutes.levelSelect);
        } else {
          navigator.pushReplacementNamed(AppRoutes.home);
        }
        break;
      
      case ErrorCategory.navigation:
      case ErrorCategory.unknown:
      default:
        // Generic unrecoverable error, return to Home and clear stack
        navigator.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        break;
    }
  }
}
