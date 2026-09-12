import 'daily_challenge_definition.dart';
import 'daily_challenge_progress.dart';
import '../../core/storage/game_save_manager.dart';

class DailyChallengeStorage {
  final GameSaveManager saveManager;

  DailyChallengeStorage({required this.saveManager});

  Future<void> saveChallenge(
    DailyChallengeDefinition def,
    DailyChallengeProgress prog, {
    int? streak,
    String? lastCompletedDate,
  }) async {
    final currentMap = Map<String, dynamic>.from(saveManager.playerData.dailyChallengeState);
    currentMap['definition'] = def.toJson();
    currentMap['progress'] = prog.toJson();
    if (streak != null) currentMap['streak'] = streak;
    if (lastCompletedDate != null) currentMap['lastCompletedDate'] = lastCompletedDate;
    saveManager.updateDailyChallenge(currentMap);
  }

  Future<DailyChallengeDefinition?> loadDefinition() async {
    final state = saveManager.playerData.dailyChallengeState;
    if (state.containsKey('definition')) {
      try {
        return DailyChallengeDefinition.fromJson(state['definition']);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<DailyChallengeProgress?> loadProgress() async {
    final state = saveManager.playerData.dailyChallengeState;
    if (state.containsKey('progress')) {
      try {
        return DailyChallengeProgress.fromJson(state['progress']);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  int loadStreak() {
    final state = saveManager.playerData.dailyChallengeState;
    final saved = state['streak'];
    if (saved is num) {
      return saved.toInt().clamp(1, 7);
    }
    return 1;
  }

  String? loadLastCompletedDate() {
    final state = saveManager.playerData.dailyChallengeState;
    return state['lastCompletedDate'] as String?;
  }

  Future<void> clear() async {
    saveManager.updateDailyChallenge({});
  }
}
