import '../../models/block.dart';

class SpecialLevelConfig {
  final bool enabled;
  final List<SpecialBlockType> allowedSpecialTypes;
  final int minimumConnectionForSpecial;

  const SpecialLevelConfig({
    this.enabled = true,
    this.allowedSpecialTypes = const [],
    this.minimumConnectionForSpecial = 4,
  });

  factory SpecialLevelConfig.fromJson(Map<String, dynamic> json) {
    final typesList = json['allowed'] as List<dynamic>?;
    List<SpecialBlockType> allowed = [];
    
    if (typesList != null) {
      for (var t in typesList) {
        try {
          allowed.add(SpecialBlockType.values.firstWhere((e) => e.name == t));
        } catch (_) {}
      }
    }

    return SpecialLevelConfig(
      enabled: json['enabled'] as bool? ?? true,
      allowedSpecialTypes: allowed,
      minimumConnectionForSpecial: json['minimumConnectionForSpecial'] as int? ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'allowed': allowedSpecialTypes.map((e) => e.name).toList(),
      'minimumConnectionForSpecial': minimumConnectionForSpecial,
    };
  }
}
