enum RewardType {
  coins,
  life,
  rocket,
  bomb,
  shuffle,
  colorBomb,
  stars,
  specialReward,
  cosmetic,
  eventReward
}

class Reward {
  final String id;
  final RewardType type;
  final int amount;
  final bool claimed;
  final String? source;
  final DateTime? expiration;
  final Map<String, dynamic> metadata;

  const Reward({
    required this.id,
    required this.type,
    required this.amount,
    this.claimed = false,
    this.source,
    this.expiration,
    this.metadata = const {},
  }) : assert(amount >= 0, 'amount cannot be negative');

  Reward copyWith({
    String? id,
    RewardType? type,
    int? amount,
    bool? claimed,
    String? source,
    DateTime? expiration,
    Map<String, dynamic>? metadata,
  }) {
    return Reward(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      claimed: claimed ?? this.claimed,
      source: source ?? this.source,
      expiration: expiration ?? this.expiration,
      metadata: metadata ?? this.metadata,
    );
  }
}
