import '../../../app/routes/routes.dart';
import '../../../game/challenges/daily_challenge_manager.dart';
import '../../../game/events/event_manager.dart';
import '../../../game/rewards/reward_manager.dart';
import '../date_service.dart';
import 'local_notification_definition.dart';
import 'notification_payload.dart';
import 'notification_type.dart';

/// Decides exactly what local notifications should be scheduled based on game state.
class NotificationScheduler {
  final DailyChallengeManager dailyChallengeManager;
  final EventManager eventManager;
  final RewardManager rewardManager;
  final DateService dateService;

  NotificationScheduler({
    required this.dailyChallengeManager,
    required this.eventManager,
    required this.rewardManager,
    required this.dateService,
  });

  /// Builds a deduplicated list of all valid future notifications.
  List<LocalNotificationDefinition> buildValidNotifications() {
    final List<LocalNotificationDefinition> result = [];
    final now = dateService.now();

    // 1. Daily Challenge Reminder (8 PM today if not completed)
    if (!dailyChallengeManager.isCompleted) {
      final today8PM = DateTime(now.year, now.month, now.day, 20, 0);
      if (today8PM.isAfter(now)) {
        final dateKey = dateService.getTodayDateKey();
        result.add(LocalNotificationDefinition(
          notificationId: 'daily_challenge_$dateKey',
          type: NotificationType.dailyChallenge,
          titleKey: 'notification_challenge_title',
          bodyKey: 'notification_challenge_body',
          scheduledTime: today8PM,
          payload: const NotificationPayload(route: AppRoutes.challenges),
        ));
      }
    }

    // 2. Unclaimed Reward Reminder
    if (rewardManager.hasUnclaimedRewards) {
      final tomorrowNoon = DateTime(now.year, now.month, now.day + 1, 12, 0);
      result.add(LocalNotificationDefinition(
        notificationId: 'unclaimed_reward',
        type: NotificationType.rewardReminder,
        titleKey: 'notification_reward_title',
        bodyKey: 'notification_reward_body',
        scheduledTime: tomorrowNoon,
        payload: const NotificationPayload(route: AppRoutes.rewards),
      ));
    }

    // 3. Event Ending Reminders (2 hours before end)
    for (final event in eventManager.activeEvents) {
      final endTime = event.endTime;
      final timeUntilEnd = endTime.difference(now);

      if (timeUntilEnd.isNegative) continue;

      if (timeUntilEnd.inHours <= 24) {
        final remindAt = endTime.subtract(const Duration(hours: 2));
        if (remindAt.isAfter(now)) {
          result.add(LocalNotificationDefinition(
            notificationId: 'event_${event.id}_ending',
            type: NotificationType.eventReminder,
            titleKey: 'notification_event_ending_title',
            bodyKey: 'notification_event_ending_body',
            scheduledTime: remindAt,
            payload: NotificationPayload(
              route: AppRoutes.eventDetail,
              arguments: {'eventId': event.id},
            ),
          ));
        }
      }
    }

    // 4. Daily General Reminder (Tomorrow at 9 AM)
    final tomorrow9AM = DateTime(now.year, now.month, now.day + 1, 9, 0);
    result.add(LocalNotificationDefinition(
      notificationId: 'daily_reminder',
      type: NotificationType.dailyReminder,
      titleKey: 'notification_daily_title',
      bodyKey: 'notification_daily_body',
      scheduledTime: tomorrow9AM,
      repeatType: 'daily',
      payload: NotificationPayload.home(),
    ));

    return result;
  }
}
