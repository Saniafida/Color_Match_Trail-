import '../../core/storage/game_save_manager.dart';

class RewardClaimStore {
  final GameSaveManager saveManager;

  RewardClaimStore({required this.saveManager});

  Future<Set<String>> _getClaimed() async {
    final stats = saveManager.playerData.statistics;
    if (stats.containsKey('claimed_rewards')) {
      final list = stats['claimed_rewards'] as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    }
    return {};
  }

  Future<bool> hasClaimed(String claimId) async {
    if (claimId.isEmpty) return false;
    final claims = await _getClaimed();
    return claims.contains(claimId);
  }

  Future<void> markClaimed(String claimId) async {
    if (claimId.isEmpty) return;
    final claims = await _getClaimed();
    claims.add(claimId);
    
    final stats = Map<String, dynamic>.from(saveManager.playerData.statistics);
    stats['claimed_rewards'] = claims.toList();
    saveManager.updateStatistics(stats);
  }
}
