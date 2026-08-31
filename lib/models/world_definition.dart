class WorldDefinition {
  final String worldId;
  final String titleKey;
  final String descriptionKey;
  final String mapAsset;
  final String backgroundAsset;
  final List<String> levelIds;
  final String firstLevelId;
  final String lastLevelId;
  final int unlockRequirement; // Number of stars needed to unlock
  final String? requiredLevelId; // Level that must be completed before unlocking
  final int rewardCoins;
  final bool enabled;

  const WorldDefinition({
    required this.worldId,
    required this.titleKey,
    required this.descriptionKey,
    this.mapAsset = '',
    this.backgroundAsset = '',
    required this.levelIds,
    this.firstLevelId = '',
    this.lastLevelId = '',
    this.unlockRequirement = 0,
    this.requiredLevelId,
    this.rewardCoins = 100,
    this.enabled = true,
  });

  factory WorldDefinition.fromJson(Map<String, dynamic> json) {
    final ids = (json['levelIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final bgAsset = json['backgroundAsset'] as String? ?? json['mapAsset'] as String? ?? '';
    final mapAsset = json['mapAsset'] as String? ?? bgAsset;

    return WorldDefinition(
      worldId: json['worldId'] as String,
      titleKey: json['titleKey'] as String? ?? '',
      descriptionKey: json['descriptionKey'] as String? ?? '',
      mapAsset: mapAsset,
      backgroundAsset: bgAsset,
      levelIds: ids,
      firstLevelId: json['firstLevelId'] as String? ?? (ids.isNotEmpty ? ids.first : ''),
      lastLevelId: json['lastLevelId'] as String? ?? (ids.isNotEmpty ? ids.last : ''),
      unlockRequirement: json['unlockRequirement'] as int? ?? 0,
      requiredLevelId: json['requiredLevelId'] as String?,
      rewardCoins: json['rewardCoins'] as int? ?? 100,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  WorldDefinition copyWith({
    String? worldId,
    String? titleKey,
    String? descriptionKey,
    String? mapAsset,
    String? backgroundAsset,
    List<String>? levelIds,
    String? firstLevelId,
    String? lastLevelId,
    int? unlockRequirement,
    String? requiredLevelId,
    int? rewardCoins,
    bool? enabled,
  }) {
    return WorldDefinition(
      worldId: worldId ?? this.worldId,
      titleKey: titleKey ?? this.titleKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      mapAsset: mapAsset ?? this.mapAsset,
      backgroundAsset: backgroundAsset ?? this.backgroundAsset,
      levelIds: levelIds ?? this.levelIds,
      firstLevelId: firstLevelId ?? this.firstLevelId,
      lastLevelId: lastLevelId ?? this.lastLevelId,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      requiredLevelId: requiredLevelId ?? this.requiredLevelId,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worldId': worldId,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'mapAsset': mapAsset,
      'backgroundAsset': backgroundAsset,
      'levelIds': levelIds,
      'firstLevelId': firstLevelId,
      'lastLevelId': lastLevelId,
      'unlockRequirement': unlockRequirement,
      if (requiredLevelId != null) 'requiredLevelId': requiredLevelId,
      'rewardCoins': rewardCoins,
      'enabled': enabled,
    };
  }
}
