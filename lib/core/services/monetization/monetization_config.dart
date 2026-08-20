import '../../../game/rewards/reward_definition.dart';

class MonetizationConfig {
  /// Default interstitial interval (levels).
  static const int interstitialFrequencyLevels = 3;

  /// Minimum number of app sessions before an interstitial can be shown.
  static const int minimumSessionCountForInterstitial = 2;

  /// Map of placement IDs to reward definitions.
  static final Map<String, RewardDefinition> rewardedPlacements = {
    'rewarded_continue': const RewardDefinition(
      id: 'rewarded_continue',
      type: RewardType.extraMoves,
      amount: 5,
      source: 'ad_reward',
    ),
    'rewarded_coins_offer': const RewardDefinition(
      id: 'rewarded_coins_offer',
      type: RewardType.coins,
      amount: 50,
      source: 'ad_reward',
    ),
    'rewarded_booster_offer': const RewardDefinition(
      id: 'rewarded_booster_offer',
      type: RewardType.booster,
      itemId: 'hammer',
      amount: 1,
      source: 'ad_reward',
    ),
  };
}
