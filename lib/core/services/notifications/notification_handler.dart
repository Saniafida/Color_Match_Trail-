import '../../../app/routes/routes.dart';
import 'notification_payload.dart';

/// Handles taps on notifications and resolves their route.
/// The navigator key is provided by the app so this handler can navigate
/// from any context (foreground, background, closed).
class NotificationHandler {
  static void handleTap({
    required NotificationPayload payload,
    required void Function(String route, {Object? arguments}) navigateTo,
  }) {
    try {
      if (payload.route.isNotEmpty) {
        // Simple argument extraction (e.g. eventId)
        if (payload.arguments.isNotEmpty && payload.arguments.containsKey('eventId')) {
          navigateTo(payload.route, arguments: payload.arguments['eventId']);
        } else {
          navigateTo(payload.route);
        }
      } else {
        navigateTo(AppRoutes.home);
      }
    } catch (_) {
      // Safe fallback — never crash from a bad payload
      navigateTo(AppRoutes.home);
    }
  }
}
