class GameDataVersion {
  final int schemaVersion;
  final int dataVersion;

  const GameDataVersion({
    required this.schemaVersion,
    required this.dataVersion,
  });

  factory GameDataVersion.fromJson(Map<String, dynamic> json) {
    return GameDataVersion(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      dataVersion: json['dataVersion'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'dataVersion': dataVersion,
    };
  }

  bool isNewerThan(GameDataVersion other) {
    if (schemaVersion > other.schemaVersion) return true;
    if (schemaVersion == other.schemaVersion && dataVersion > other.dataVersion) return true;
    return false;
  }
}
