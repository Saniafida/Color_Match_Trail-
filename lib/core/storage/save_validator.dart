import 'player_save_data.dart';

class SaveValidator {
  static PlayerSaveData validateAndCorrect(PlayerSaveData data) {
    int safeCoins = data.coins;
    if (safeCoins < 0) {
      safeCoins = 0;
    }

    final safeBoosterInventory = <String, dynamic>{};
    data.boosterInventory.forEach((key, value) {
      if (value is int && value >= 0) {
        safeBoosterInventory[key] = value;
      } else {
        safeBoosterInventory[key] = 0;
      }
    });

    final safeCampaignProgress = <String, dynamic>{};
    data.campaignProgress.forEach((key, value) {
      if (key == 'highestUnlockedLevel' && value is int && value < 1) {
        safeCampaignProgress[key] = 1;
      } else {
        safeCampaignProgress[key] = value;
      }
    });

    return data.copyWith(
      coins: safeCoins,
      boosterInventory: safeBoosterInventory,
      campaignProgress: safeCampaignProgress,
    );
  }
}
