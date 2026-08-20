import 'ad_result.dart';

abstract class AdService {
  Future<void> initialize();
  
  Future<void> loadRewarded(String placementId);
  bool isRewardedReady(String placementId);
  Future<AdResult> showRewarded(String placementId);

  Future<void> loadInterstitial(String placementId);
  bool isInterstitialReady(String placementId);
  Future<AdResult> showInterstitial(String placementId);

  Future<void> dispose();
}

/// A stub implementation of AdService for use before real ads are integrated.
class StubAdService implements AdService {
  final Set<String> _readyPlacements = {};

  @override
  Future<void> initialize() async {
    // Stub initialization
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> loadRewarded(String placementId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _readyPlacements.add(placementId);
  }

  @override
  bool isRewardedReady(String placementId) {
    return _readyPlacements.contains(placementId);
  }

  @override
  Future<AdResult> showRewarded(String placementId) async {
    if (!isRewardedReady(placementId)) {
      return const AdResult(status: AdResultStatus.unavailable, message: 'Ad not ready');
    }
    
    // Simulate showing an ad and it completing successfully
    _readyPlacements.remove(placementId); // Consume the ad
    
    // Real implementation would wait for ad completion callback
    await Future.delayed(const Duration(seconds: 1));
    return const AdResult(status: AdResultStatus.completed, message: 'Reward earned');
  }

  @override
  Future<void> loadInterstitial(String placementId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _readyPlacements.add(placementId);
  }

  @override
  bool isInterstitialReady(String placementId) {
    return _readyPlacements.contains(placementId);
  }

  @override
  Future<AdResult> showInterstitial(String placementId) async {
    if (!isInterstitialReady(placementId)) {
      return const AdResult(status: AdResultStatus.unavailable, message: 'Ad not ready');
    }

    // Consume the ad
    _readyPlacements.remove(placementId);
    
    // Simulate showing an ad and it closing
    await Future.delayed(const Duration(seconds: 1));
    return const AdResult(status: AdResultStatus.dismissed, message: 'Ad closed');
  }

  @override
  Future<void> dispose() async {
    _readyPlacements.clear();
  }
}
