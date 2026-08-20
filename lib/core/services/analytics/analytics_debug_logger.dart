import 'package:flutter/foundation.dart';
import 'analytics_error.dart';
import 'analytics_event.dart';

class AnalyticsDebugLogger {
  void logEvent(AnalyticsEvent event) {
    debugPrint('📊 [ANALYTICS EVENT] ${event.name}');
    if (event.parameters.isNotEmpty) {
      debugPrint('   Parameters: ${event.parameters}');
    }
  }

  void logScreen(String screenName) {
    debugPrint('📱 [ANALYTICS SCREEN] Viewed: $screenName');
  }

  void logError(AnalyticsError error) {
    debugPrint('❌ [ANALYTICS ERROR] [${error.module}] ${error.type}: ${error.safeMessage}');
  }

  void logUserProperty(String key, dynamic value) {
    debugPrint('👤 [ANALYTICS PROPERTY] Set $key = $value');
  }
}
