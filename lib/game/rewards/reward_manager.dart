import 'package:flutter/foundation.dart';
import '../coins/coin_manager.dart';
import '../inventory/inventory_manager.dart';
import '../../models/booster.dart';
import 'reward_definition.dart';
import 'reward_result.dart';
import 'reward_claim_store.dart';

class RewardManager extends ChangeNotifier {
  final CoinManager coinManager;
  final InventoryManager inventoryManager;
  final RewardClaimStore claimStore;

  final Set<String> _inFlightClaims = {};

  RewardManager({
    required this.coinManager,
    required this.inventoryManager,
    required this.claimStore,
  });

  /// In an offline architecture, this might check if a daily reward or offline box is ready.
  /// Stubbed to false by default unless a specific local unclaimed queue is implemented.
  bool get hasUnclaimedRewards => false;

  Future<RewardResult> grantReward(RewardDefinition reward, {String? uniqueClaimId}) async {
    // 1. Validation & Double-claim prevention
    if (uniqueClaimId != null) {
      if (_inFlightClaims.contains(uniqueClaimId)) {
        return const RewardResult(status: RewardResultStatus.alreadyClaimed, message: 'Transaction in progress');
      }
      
      _inFlightClaims.add(uniqueClaimId);
      
      try {
        final alreadyClaimed = await claimStore.hasClaimed(uniqueClaimId);
        if (alreadyClaimed) {
          _inFlightClaims.remove(uniqueClaimId);
          return const RewardResult(status: RewardResultStatus.alreadyClaimed, message: 'Reward already claimed');
        }
      } catch (e) {
        _inFlightClaims.remove(uniqueClaimId);
        return const RewardResult(status: RewardResultStatus.failed, message: 'Failed to validate claim');
      }
    }

    if (reward.amount <= 0) {
      if (uniqueClaimId != null) _inFlightClaims.remove(uniqueClaimId);
      return const RewardResult(status: RewardResultStatus.failed, message: 'Invalid reward amount');
    }

    // 2. Granting logic
    bool success = false;
    try {
      if (reward.type == RewardType.coins) {
        success = await coinManager.addCoins(reward.amount);
      } else if (reward.type == RewardType.booster && reward.itemId != null) {
        final type = BoosterType.values.firstWhere(
          (e) => e.name == reward.itemId,
          orElse: () => BoosterType.hammer,
        );
        success = await inventoryManager.addBooster(type, reward.amount);
      } else if (reward.type == RewardType.extraMoves) {
        // Handled directly if extraMoves was treated as a booster or handled by a level logic somewhere.
        // For now, if we treat it as a booster inventory item:
        success = await inventoryManager.addBooster(BoosterType.extraMoves, reward.amount);
      }
    } catch (e) {
      success = false;
    }

    // 3. Complete transaction
    if (success && uniqueClaimId != null) {
      await claimStore.markClaimed(uniqueClaimId);
    }

    if (uniqueClaimId != null) {
      _inFlightClaims.remove(uniqueClaimId);
    }

    if (success) {
      notifyListeners();
      return const RewardResult(status: RewardResultStatus.success);
    } else {
      return const RewardResult(status: RewardResultStatus.failed, message: 'Failed to grant reward');
    }
  }

  Future<RewardResult> grantRewards(List<RewardDefinition> rewards, {String? uniqueClaimId}) async {
    // If a claim ID is provided for the batch:
    if (uniqueClaimId != null) {
      if (_inFlightClaims.contains(uniqueClaimId)) {
        return const RewardResult(status: RewardResultStatus.alreadyClaimed, message: 'Transaction in progress');
      }
      _inFlightClaims.add(uniqueClaimId);
      
      final alreadyClaimed = await claimStore.hasClaimed(uniqueClaimId);
      if (alreadyClaimed) {
        _inFlightClaims.remove(uniqueClaimId);
        return const RewardResult(status: RewardResultStatus.alreadyClaimed, message: 'Rewards already claimed');
      }
    }

    int successCount = 0;
    
    // We do NOT pass the uniqueClaimId to the individual grants so they don't lock each other,
    // we handle the batch claim completion at the end.
    for (final r in rewards) {
      final res = await grantReward(r); // Individual grants don't check uniqueness
      if (res.isSuccess) successCount++;
    }

    if (successCount > 0 && uniqueClaimId != null) {
      await claimStore.markClaimed(uniqueClaimId);
    }

    if (uniqueClaimId != null) {
      _inFlightClaims.remove(uniqueClaimId);
    }

    if (successCount == rewards.length) {
      return const RewardResult(status: RewardResultStatus.success);
    } else if (successCount > 0) {
      return const RewardResult(status: RewardResultStatus.partial, message: 'Some rewards failed');
    } else {
      return const RewardResult(status: RewardResultStatus.failed, message: 'All rewards failed');
    }
  }
}
