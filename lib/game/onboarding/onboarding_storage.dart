import '../../core/storage/game_save_manager.dart';
import 'onboarding_state.dart';

class OnboardingStorage {
  final GameSaveManager saveManager;

  OnboardingStorage({required this.saveManager});

  Future<void> save(OnboardingState state) async {
    saveManager.updateOnboarding(state.toJson());
    // Onboarding is critical — persist immediately
    await saveManager.saveNow();
  }

  OnboardingState load() {
    final map = saveManager.playerData.onboarding;
    if (map.isEmpty) return OnboardingState.defaults();
    try {
      return OnboardingState.fromJson(map);
    } catch (_) {
      return OnboardingState.defaults();
    }
  }
}
