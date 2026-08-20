import 'event_definition.dart';

class EventValidator {
  static bool isValid(EventDefinition event) {
    if (event.id.isEmpty) return false;
    if (event.name.isEmpty) return false;
    if (event.endTime.isBefore(event.startTime) || event.endTime.isAtSameMomentAs(event.startTime)) return false;
    if (event.target <= 0) return false;
    if (event.rewardId.isEmpty) return false;
    if (event.rewardAmount <= 0) return false;
    return true;
  }
}
