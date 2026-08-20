class SpawnConfiguration {
  final List<String> availableColors;
  final Map<String, int> spawnWeights;
  final int maximumColors;
  final List<String> specialSpawnRules;

  const SpawnConfiguration({
    this.availableColors = const [],
    this.spawnWeights = const {},
    this.maximumColors = 6,
    this.specialSpawnRules = const [],
  });

  factory SpawnConfiguration.fromJson(Map<String, dynamic> json) {
    return SpawnConfiguration(
      availableColors: (json['availableColors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      spawnWeights: (json['spawnWeights'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? {},
      maximumColors: json['maximumColors'] as int? ?? 6,
      specialSpawnRules: (json['specialSpawnRules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
