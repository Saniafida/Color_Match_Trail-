/// Encapsulates routing information for a notification tap.
class NotificationPayload {
  final String route;
  final Map<String, dynamic> arguments;

  const NotificationPayload({
    required this.route,
    this.arguments = const {},
  });

  /// Factory for empty or default routing
  factory NotificationPayload.home() {
    return const NotificationPayload(route: '/home');
  }

  /// Parses from stringified local notification library payload
  factory NotificationPayload.fromString(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) {
      return NotificationPayload.home();
    }
    
    // In a real implementation this would parse JSON from the notification library.
    // For this offline architectural setup, we assume it's just the route string 
    // or handled directly if complex payload parsing is needed.
    return NotificationPayload(route: payloadStr);
  }

  String get asString => route; // simplified for stub
}
