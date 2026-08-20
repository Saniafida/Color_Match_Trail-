import 'event_progress.dart';
import '../../core/storage/game_save_manager.dart';

class EventStorage {
  final GameSaveManager saveManager;

  EventStorage({required this.saveManager});

  Future<void> saveProgress(EventProgress progress) async {
    final state = Map<String, dynamic>.from(saveManager.playerData.eventProgress);
    state[progress.eventId] = progress.toJson();
    saveManager.updateEventProgress(state);
  }

  Future<EventProgress?> loadProgress(String eventId) async {
    final state = saveManager.playerData.eventProgress;
    if (state.containsKey(eventId)) {
      try {
        return EventProgress.fromJson(state[eventId]);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
