class BlockDefinition {
  final String blockType;
  final String color;
  final String asset;
  final String specialBehavior;
  final int spawnWeight;
  final bool enabled;

  const BlockDefinition({
    required this.blockType,
    required this.color,
    required this.asset,
    this.specialBehavior = 'none',
    this.spawnWeight = 100,
    this.enabled = true,
  });

  factory BlockDefinition.fromJson(Map<String, dynamic> json) {
    return BlockDefinition(
      blockType: json['blockType'] as String,
      color: json['color'] as String? ?? 'none',
      asset: json['asset'] as String? ?? '',
      specialBehavior: json['specialBehavior'] as String? ?? 'none',
      spawnWeight: json['spawnWeight'] as int? ?? 100,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
