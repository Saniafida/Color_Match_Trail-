import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../game/rewards/reward_manager.dart';
import '../../../game/onboarding/onboarding_manager.dart';
import 'ad_consent_manager.dart';
import 'ad_free_manager.dart';
import 'ad_frequency_controller.dart';
import 'ad_result.dart';
import 'ad_service.dart';
import 'monetization_config.dart';

class MonetizationManager extends ChangeNotifier {
  final AdService adService;
  final AdConsentManager consentManager;
  final AdFreeManager adFreeManager;
  final AdFrequencyController frequencyController;
  final RewardManager rewardManager;
  final OnboardingManager onboardingManager;

  bool _initialized = false;
  bool _adsEnabled = true; // Can be toggled for dev testing or remote config

  MonetizationManager({
    required this.adService,
    required this.consentManager,
    required this.adFreeManager,
    required this.frequencyController,
    required this.rewardManager,
    required this.onboardingManager,
  });

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Check consent state
    final consent = await consentManager.checkConsent();
    if (consent == AdConsentStatus.denied) {
      _adsEnabled = false;
    }

    if (_adsEnabled) {
      await adService.initialize();
      // Preload commonly used ads
      adService.loadRewarded('rewarded_continue');
      adService.loadRewarded('rewarded_coins_offer');
      adService.loadRewarded('rewarded_booster_offer');
      adService.loadInterstitial('interstitial_level_complete');
    }

    _initialized = true;
    notifyListeners();
  }

  /// App lifecycle hook: Call when app foregrounds to track sessions
  void onAppForegrounded() {
    frequencyController.incrementSessionCount();
  }

  /// App lifecycle hook: Call when a level finishes to track pacing
  void onLevelCompleted() {
    frequencyController.incrementLevelsPlayed();
  }

  bool isRewardedReady(String placementId) {
    if (!_adsEnabled) return false;
    return adService.isRewardedReady(placementId);
  }

  Future<AdResult> showRewarded(String placementId) async {
    if (!_adsEnabled) {
      return const AdResult(status: AdResultStatus.unavailable, message: 'Ads disabled');
    }

    if (!adService.isRewardedReady(placementId)) {
      // Try to load for next time
      adService.loadRewarded(placementId);
      return const AdResult(status: AdResultStatus.unavailable, message: 'Ad not ready');
    }

    // Show the ad
    final result = await adService.showRewarded(placementId);

    // If successful, grant reward
    if (result.status == AdResultStatus.completed) {
      final rewardDef = MonetizationConfig.rewardedPlacements[placementId];
      if (rewardDef != null) {
        // Generate unique transaction ID to prevent double-granting
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = Random().nextInt(10000);
        final txId = 'ad_reward_${placementId}_${timestamp}_$random';

        final rewardResult = await rewardManager.grantReward(
          rewardDef,
          uniqueClaimId: txId,
        );
        
        if (!rewardResult.isSuccess) {
          debugPrint('Failed to grant ad reward: ${rewardResult.message}');
        }
      } else {
        debugPrint('Warning: No reward definition found for placement $placementId');
      }
    }

    // Preload next ad for this placement
    adService.loadRewarded(placementId);

    return result;
  }

  /// Evaluates whether an interstitial should be shown right now and shows it if so.
  /// Used for natural break points (e.g., between levels).
  Future<AdResult> showInterstitialIfAppropriate(String placementId) async {
    if (!_adsEnabled) {
      return const AdResult(status: AdResultStatus.unavailable, message: 'Ads disabled');
    }

    if (adFreeManager.isAdFree) {
      return const AdResult(status: AdResultStatus.unavailable, message: 'Ad-free purchased');
    }

    if (!onboardingManager.state.completed) {
      return const AdResult(status: AdResultStatus.unavailable, message: 'In onboarding');
    }

    if (!frequencyController.shouldShowInterstitial()) {
      return const AdResult(status: AdResultStatus.unavailable, message: 'Frequency cap active');
    }

    if (!adService.isInterstitialReady(placementId)) {
      adService.loadInterstitial(placementId);
      return const AdResult(status: AdResultStatus.unavailable, message: 'Ad not ready');
    }

    final result = await adService.showInterstitial(placementId);
    
    if (result.status == AdResultStatus.dismissed || result.status == AdResultStatus.completed) {
      frequencyController.recordAdShown();
    }

    // Preload next
    adService.loadInterstitial(placementId);

    return result;
  }

  @override
  void dispose() {
    adService.dispose();
    super.dispose();
  }
}
