import '../../models/block.dart';

enum SpawnDistribution { uniform, weighted }

class SpawnConfig {
  final List<BlockColor> allowedColors;
  final SpawnDistribution distribution;
  final bool avoidImmediateMatch;
  final bool avoidImmediateMatchOnSpawn;

  const SpawnConfig({
    this.allowedColors = const [],
    this.distribution = SpawnDistribution.uniform,
    this.avoidImmediateMatch = true,
    this.avoidImmediateMatchOnSpawn = true,
  });

  factory SpawnConfig.fromJson(Map<String, dynamic> json) {
    final colorsList = json['allowedColors'] as List<dynamic>?;
    List<BlockColor> allowed = [];
    if (colorsList != null) {
      for (var c in colorsList) {
        try {
          allowed.add(BlockColor.values.firstWhere((e) => e.name == c));
        } catch (_) {}
      }
    }

    SpawnDistribution dist = SpawnDistribution.uniform;
    if (json['distribution'] != null) {
      try {
        dist = SpawnDistribution.values.firstWhere((e) => e.name == json['distribution']);
      } catch (_) {}
    }

    return SpawnConfig(
      allowedColors: allowed,
      distribution: dist,
      avoidImmediateMatch: json['avoidImmediateMatch'] as bool? ?? true,
      avoidImmediateMatchOnSpawn: json['avoidImmediateMatchOnSpawn'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (allowedColors.isNotEmpty) 'allowedColors': allowedColors.map((e) => e.name).toList(),
      'distribution': distribution.name,
      'avoidImmediateMatch': avoidImmediateMatch,
      'avoidImmediateMatchOnSpawn': avoidImmediateMatchOnSpawn,
    };
  }
}
