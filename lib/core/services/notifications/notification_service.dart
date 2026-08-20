import 'local_notification_definition.dart';

/// Abstract service handling local platform notification implementation.
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> schedule(LocalNotificationDefinition notification);
  Future<void> cancel(String notificationId);
  Future<void> cancelAll();
  void dispose();
}

/// Stub implementation — does nothing but satisfies the interface safely offline.
/// Swap for `flutter_local_notifications` when required.
class StubNotificationService implements NotificationService {
  final Set<String> _pending = {};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    // In a stub, assume permission granted to test logic locally.
    return true; 
  }

  @override
  Future<bool> schedule(LocalNotificationDefinition notification) async {
    if (!_initialized) return false;
    if (!notification.enabled) return false;
    if (!notification.isInFuture) return false;
    
    _pending.add(notification.notificationId);
    return true;
  }

  @override
  Future<void> cancel(String notificationId) async {
    _pending.remove(notificationId);
  }

  @override
  Future<void> cancelAll() async {
    _pending.clear();
  }

  @override
  void dispose() {}
}
