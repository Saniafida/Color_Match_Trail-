import '../../core/storage/game_save_manager.dart';
import 'achievement_progress.dart';

class AchievementStorage {
  final GameSaveManager saveManager;

  AchievementStorage({required this.saveManager});

  Future<void> saveProgress(AchievementProgress progress) async {
    final state = Map<String, dynamic>.from(saveManager.playerData.achievements);
    state[progress.achievementId] = progress.toJson();
    saveManager.updateAchievements(state);
  }

  Future<void> saveAllProgress(List<AchievementProgress> progresses) async {
    final state = Map<String, dynamic>.from(saveManager.playerData.achievements);
    for (var p in progresses) {
      state[p.achievementId] = p.toJson();
    }
    saveManager.updateAchievements(state);
  }

  Future<AchievementProgress?> loadProgress(String achievementId) async {
    final state = saveManager.playerData.achievements;
    if (state.containsKey(achievementId)) {
      try {
        return AchievementProgress.fromJson(state[achievementId]);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<Map<String, AchievementProgress>> loadAllProgress() async {
    final state = saveManager.playerData.achievements;
    final Map<String, AchievementProgress> result = {};
    for (var key in state.keys) {
      try {
        result[key] = AchievementProgress.fromJson(state[key]);
      } catch (e) {
        // ignore
      }
    }
    return result;
  }
}
