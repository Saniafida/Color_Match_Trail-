import 'analytics_config.dart';
import 'analytics_error.dart';
import 'analytics_event.dart';

abstract class AnalyticsService {
  Future<void> initialize(AnalyticsConfig config);
  Future<void> logEvent(AnalyticsEvent event);
  Future<void> logScreenView(String screenName);
  Future<void> logError(AnalyticsError error);
  Future<void> setUserProperty(String key, dynamic value);
  Future<void> setEnabled(bool enabled);
  Future<void> dispose();
}

/// A stub implementation that ignores all events.
/// This will be replaced with a real provider (like FirebaseAnalytics) later.
class StubAnalyticsService implements AnalyticsService {
  bool _enabled = true;

  @override
  Future<void> initialize(AnalyticsConfig config) async {
    _enabled = config.enabled;
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    if (!_enabled) return;
    // Stub implementation does nothing.
  }

  @override
  Future<void> logScreenView(String screenName) async {
    if (!_enabled) return;
    // Stub implementation does nothing.
  }

  @override
  Future<void> logError(AnalyticsError error) async {
    if (!_enabled) return;
    // Stub implementation does nothing.
  }

  @override
  Future<void> setUserProperty(String key, dynamic value) async {
    if (!_enabled) return;
    // Stub implementation does nothing.
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }

  @override
  Future<void> dispose() async {
    // Clean up if needed
  }
}
