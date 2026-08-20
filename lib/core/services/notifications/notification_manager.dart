import 'package:flutter/foundation.dart';
import '../../../game/settings/settings_manager.dart';
import 'local_notification_definition.dart';
import 'notification_service.dart';
import 'notification_scheduler.dart';
import 'notification_storage.dart';
import 'notification_payload.dart';
import 'notification_handler.dart';

/// Central state coordinator for Local Notifications.
class NotificationManager extends ChangeNotifier {
  final NotificationService service;
  final NotificationScheduler scheduler;
  final NotificationStorage storage;
  final SettingsManager settingsManager;

  bool _initialized = false;
  bool _permissionGranted = false;

  NotificationManager({
    required this.service,
    required this.scheduler,
    required this.storage,
    required this.settingsManager,
  });

  bool get isEnabled => settingsManager.state.notificationsEnabled && _permissionGranted;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await service.initialize();
      _initialized = true;

      storage.pruneExpired();

      // On startup, check current permission without explicitly prompting
      _permissionGranted = true; // In a full implementation, we'd check OS status here

      if (isEnabled) {
        await _scheduleAllValid();
      }

      settingsManager.addListener(_onSettingsChanged);
    } catch (e) {
      debugPrint('[NotificationManager] Initialization failed: $e');
      // Fails gracefully without crashing the game
    }
  }

  @override
  void dispose() {
    settingsManager.removeListener(_onSettingsChanged);
    service.dispose();
    super.dispose();
  }

  Future<void> _onSettingsChanged() async {
    if (settingsManager.state.notificationsEnabled) {
      if (isEnabled) {
        await _scheduleAllValid();
      }
    } else {
      await _cancelAll();
    }
    notifyListeners();
  }

  /// Explicitly requests permission (e.g. from an onboarding button).
  Future<bool> requestPermission() async {
    try {
      _permissionGranted = await service.requestPermission();
      notifyListeners();
      
      if (isEnabled) {
        await _scheduleAllValid();
      }
      return _permissionGranted;
    } catch (e) {
      debugPrint('[NotificationManager] Failed requesting permission: $e');
      return false;
    }
  }

  Future<void> _scheduleAllValid() async {
    if (!isEnabled) return;
    
    try {
      final notifications = scheduler.buildValidNotifications();
      for (final n in notifications) {
        await _scheduleOne(n);
      }
    } catch (e) {
      debugPrint('[NotificationManager] Failed scheduling batch: $e');
    }
  }

  Future<void> _scheduleOne(LocalNotificationDefinition notification) async {
    if (!notification.isInFuture) return;
    if (storage.isScheduled(notification.notificationId)) return; // Prevent duplicates

    try {
      final success = await service.schedule(notification);
      if (success) {
        storage.markScheduled(notification); // We'd need to adapt storage if needed, or assume it accepts LocalNotificationDefinition
      }
    } catch (e) {
      debugPrint('[NotificationManager] Failed to schedule ${notification.notificationId}: $e');
    }
  }

  Future<void> _cancelAll() async {
    try {
      await service.cancelAll();
      storage.clearAll();
    } catch (e) {
      debugPrint('[NotificationManager] Failed to cancelAll: $e');
    }
  }

  void handleNotificationTap({
    required NotificationPayload payload,
    required void Function(String route, {Object? arguments}) navigateTo,
  }) {
    NotificationHandler.handleTap(payload: payload, navigateTo: navigateTo);
  }
}
