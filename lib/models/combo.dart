class Combo {
  final int comboCount;
  final int lastConnectedCount;
  final int totalBlocksCleared;
  final double multiplier;
  final bool isActive;
  final DateTime? startedAt;

  const Combo({
    this.comboCount = 0,
    this.lastConnectedCount = 0,
    this.totalBlocksCleared = 0,
    this.multiplier = 1.0,
    this.isActive = false,
    this.startedAt,
  });

  Combo copyWith({
    int? comboCount,
    int? lastConnectedCount,
    int? totalBlocksCleared,
    double? multiplier,
    bool? isActive,
    DateTime? startedAt,
  }) {
    return Combo(
      comboCount: comboCount ?? this.comboCount,
      lastConnectedCount: lastConnectedCount ?? this.lastConnectedCount,
      totalBlocksCleared: totalBlocksCleared ?? this.totalBlocksCleared,
      multiplier: multiplier ?? this.multiplier,
      isActive: isActive ?? this.isActive,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
