import '../../storage/game_save_manager.dart';
import 'monetization_config.dart';

class AdFrequencyController {
  final GameSaveManager saveManager;

  static const String _levelsSinceAdKey = 'levelsSinceLastAd';
  static const String _sessionCountKey = 'appSessionCount';

  AdFrequencyController({required this.saveManager});

  /// Call this when the app starts or comes to the foreground
  void incrementSessionCount() {
    final monetization = Map<String, dynamic>.from(saveManager.playerData.monetization);
    final currentCount = monetization[_sessionCountKey] as int? ?? 0;
    monetization[_sessionCountKey] = currentCount + 1;
    saveManager.updateMonetization(monetization);
  }

  /// Call this when a level is completed
  void incrementLevelsPlayed() {
    final monetization = Map<String, dynamic>.from(saveManager.playerData.monetization);
    final currentCount = monetization[_levelsSinceAdKey] as int? ?? 0;
    monetization[_levelsSinceAdKey] = currentCount + 1;
    saveManager.updateMonetization(monetization);
  }

  /// Check if it's appropriate to show an interstitial
  bool shouldShowInterstitial() {
    final monetization = saveManager.playerData.monetization;
    
    // First-session protection
    final sessionCount = monetization[_sessionCountKey] as int? ?? 1;
    if (sessionCount < MonetizationConfig.minimumSessionCountForInterstitial) {
      return false;
    }

    // Frequency cap
    final levelsSinceAd = monetization[_levelsSinceAdKey] as int? ?? 0;
    if (levelsSinceAd < MonetizationConfig.interstitialFrequencyLevels) {
      return false;
    }

    return true;
  }

  /// Call this when an interstitial is successfully shown
  void recordAdShown() {
    final monetization = Map<String, dynamic>.from(saveManager.playerData.monetization);
    monetization[_levelsSinceAdKey] = 0; // reset
    saveManager.updateMonetization(monetization);
  }
}
