import 'daily_challenge_definition.dart';
import 'daily_challenge_progress.dart';
import '../../core/storage/game_save_manager.dart';

class DailyChallengeStorage {
  final GameSaveManager saveManager;

  DailyChallengeStorage({required this.saveManager});

  Future<void> saveChallenge(DailyChallengeDefinition def, DailyChallengeProgress prog) async {
    saveManager.updateDailyChallenge({
      'definition': def.toJson(),
      'progress': prog.toJson(),
    });
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

  Future<void> clear() async {
    saveManager.updateDailyChallenge({});
  }
}
