import '../../../core/storage/game_save_manager.dart';
import 'local_notification_definition.dart';

/// Persists scheduled notification metadata to prevent duplicate scheduling
/// across app restarts. Uses GameSaveManager as the backing store.
class NotificationStorage {
  final GameSaveManager saveManager;

  NotificationStorage({required this.saveManager});

  Map<String, dynamic> get _raw =>
      Map<String, dynamic>.from(saveManager.playerData.scheduledNotifications);

  /// Returns true if a notification with [id] has already been persisted.
  bool isScheduled(String id) => _raw.containsKey(id);

  /// Persist a notification definition.
  void markScheduled(LocalNotificationDefinition notification) {
    final updated = _raw;
    updated[notification.notificationId] = notification.toJson();
    saveManager.updateScheduledNotifications(updated);
  }

  /// Remove a persisted notification by its id.
  void unmarkScheduled(String id) {
    final updated = _raw;
    updated.remove(id);
    saveManager.updateScheduledNotifications(updated);
  }

  /// Remove all persisted notifications.
  void clearAll() {
    saveManager.updateScheduledNotifications({});
  }

  /// Remove all persisted notifications whose scheduled time is in the past.
  void pruneExpired() {
    final now = DateTime.now();
    final updated = _raw;
    updated.removeWhere((key, value) {
      try {
        final scheduled = DateTime.parse(value['scheduledTime'] as String);
        return scheduled.isBefore(now);
      } catch (_) {
        return true; // Remove corrupt entries
      }
    });
    saveManager.updateScheduledNotifications(updated);
  }

  /// All currently persisted notification definitions.
  List<LocalNotificationDefinition> loadAll() {
    final raw = _raw;
    final List<LocalNotificationDefinition> result = [];
    for (final entry in raw.values) {
      try {
        result.add(LocalNotificationDefinition.fromJson(entry as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries
      }
    }
    return result;
  }
}
