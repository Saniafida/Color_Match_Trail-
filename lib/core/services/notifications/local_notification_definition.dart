import 'notification_type.dart';
import 'notification_payload.dart';

class LocalNotificationDefinition {
  final String notificationId;
  final NotificationType type;
  final String titleKey;
  final String bodyKey;
  final DateTime scheduledTime;
  final bool enabled;
  final NotificationPayload payload;
  final String repeatType;

  const LocalNotificationDefinition({
    required this.notificationId,
    required this.type,
    required this.titleKey,
    required this.bodyKey,
    required this.scheduledTime,
    this.enabled = true,
    required this.payload,
    this.repeatType = 'none',
  });

  bool get isInFuture => scheduledTime.isAfter(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'type': type.name,
      'titleKey': titleKey,
      'bodyKey': bodyKey,
      'scheduledTime': scheduledTime.toIso8601String(),
      'enabled': enabled,
      'payloadRoute': payload.route,
      'payloadArguments': payload.arguments,
      'repeatType': repeatType,
    };
  }

  factory LocalNotificationDefinition.fromJson(Map<String, dynamic> json) {
    return LocalNotificationDefinition(
      notificationId: json['notificationId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.customLocalReminder,
      ),
      titleKey: json['titleKey'] as String,
      bodyKey: json['bodyKey'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      enabled: json['enabled'] as bool? ?? true,
      payload: NotificationPayload(
        route: json['payloadRoute'] as String? ?? '/home',
        arguments: json['payloadArguments'] as Map<String, dynamic>? ?? {},
      ),
      repeatType: json['repeatType'] as String? ?? 'none',
    );
  }
}
