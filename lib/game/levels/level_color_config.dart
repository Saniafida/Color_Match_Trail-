import '../../models/block.dart';

class LevelColorConfig {
  final List<BlockColor> availableColors;
  final int? minimumColors;
  final int? maximumColors;

  const LevelColorConfig({
    required this.availableColors,
    this.minimumColors,
    this.maximumColors,
  });

  factory LevelColorConfig.fromJson(Map<String, dynamic> json) {
    final colorsList = json['availableColors'] as List<dynamic>?;
    List<BlockColor> colors = [];
    
    if (colorsList != null) {
      for (var c in colorsList) {
        try {
          colors.add(BlockColor.values.firstWhere((e) => e.name == c));
        } catch (_) {}
      }
    }

    return LevelColorConfig(
      availableColors: colors,
      minimumColors: json['minimumColors'] as int?,
      maximumColors: json['maximumColors'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'availableColors': availableColors.map((e) => e.name).toList(),
      if (minimumColors != null) 'minimumColors': minimumColors,
      if (maximumColors != null) 'maximumColors': maximumColors,
    };
  }
}
