enum RewardType {
  coins,
  booster,
  extraMoves,
  avatar,
  achievement,
  level,
}

class RewardDefinition {
  final String id;
  final RewardType type;
  final int amount;
  final String? itemId; // e.g., 'hammer'
  final String source;
  final String? unlockId;
  final Map<String, dynamic> metadata;

  const RewardDefinition({
    required this.id,
    required this.type,
    required this.amount,
    this.itemId,
    required this.source,
    this.unlockId,
    this.metadata = const {},
  });

  factory RewardDefinition.fromJson(Map<String, dynamic> json) {
    return RewardDefinition(
      id: json['rewardId'] as String? ?? json['id'] as String? ?? '',
      type: RewardType.values.firstWhere(
        (e) => e.name == json['rewardType'],
        orElse: () => RewardType.coins,
      ),
      amount: json['amount'] as int? ?? 1,
      itemId: json['itemId'] as String?,
      source: json['source'] as String? ?? 'data',
      unlockId: json['unlockId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
