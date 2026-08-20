class WorldDefinition {
  final String worldId;
  final String titleKey;
  final String descriptionKey;
  final List<String> levelIds;
  final int unlockRequirement; // Number of stars needed to unlock
  final String backgroundAsset;
  final bool enabled;

  const WorldDefinition({
    required this.worldId,
    required this.titleKey,
    required this.descriptionKey,
    required this.levelIds,
    this.unlockRequirement = 0,
    required this.backgroundAsset,
    this.enabled = true,
  });

  factory WorldDefinition.fromJson(Map<String, dynamic> json) {
    return WorldDefinition(
      worldId: json['worldId'] as String,
      titleKey: json['titleKey'] as String? ?? '',
      descriptionKey: json['descriptionKey'] as String? ?? '',
      levelIds: (json['levelIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      unlockRequirement: json['unlockRequirement'] as int? ?? 0,
      backgroundAsset: json['backgroundAsset'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
