enum NotificationType {
  dailyReminder,
  dailyChallenge,
  rewardReminder,
  eventReminder,
  energyReminder,
  customLocalReminder,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.dailyReminder: return 'Daily Reminder';
      case NotificationType.dailyChallenge: return 'Daily Challenge';
      case NotificationType.rewardReminder: return 'Reward Reminder';
      case NotificationType.eventReminder: return 'Event Reminder';
      case NotificationType.energyReminder: return 'Energy Reminder';
      case NotificationType.customLocalReminder: return 'Reminder';
    }
  }
}
