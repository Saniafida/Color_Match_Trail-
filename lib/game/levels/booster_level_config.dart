import '../../models/booster.dart';

class BoosterLevelConfig {
  final List<BoosterType> allowedBoosters;

  const BoosterLevelConfig({
    this.allowedBoosters = const [],
  });

  factory BoosterLevelConfig.fromJson(Map<String, dynamic> json) {
    final typesList = json['allowed'] as List<dynamic>?;
    List<BoosterType> allowed = [];
    
    if (typesList != null) {
      for (var t in typesList) {
        try {
          allowed.add(BoosterType.values.firstWhere((e) => e.name == t));
        } catch (_) {}
      }
    }

    return BoosterLevelConfig(
      allowedBoosters: allowed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowed': allowedBoosters.map((e) => e.name).toList(),
    };
  }
}
