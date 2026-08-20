import 'level_progress.dart';

class ProgressionState {
  final Map<String, LevelProgress> levels;
  final Set<String> unlockedWorlds;
  final String? currentLevel;

  const ProgressionState({
    required this.levels,
    required this.unlockedWorlds,
    this.currentLevel,
  });

  factory ProgressionState.initial() {
    return const ProgressionState(
      levels: {},
      unlockedWorlds: {},
    );
  }

  factory ProgressionState.fromJson(Map<String, dynamic> json) {
    final levelsMap = <String, LevelProgress>{};
    if (json['levels'] != null) {
      final levelsJson = json['levels'] as Map<String, dynamic>;
      levelsJson.forEach((key, value) {
        levelsMap[key] = LevelProgress.fromJson(value as Map<String, dynamic>);
      });
    }

    return ProgressionState(
      levels: levelsMap,
      unlockedWorlds: (json['unlockedWorlds'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {},
      currentLevel: json['currentLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levels': levels.map((key, value) => MapEntry(key, value.toJson())),
      'unlockedWorlds': unlockedWorlds.toList(),
      if (currentLevel != null) 'currentLevel': currentLevel,
    };
  }

  ProgressionState copyWith({
    Map<String, LevelProgress>? levels,
    Set<String>? unlockedWorlds,
    String? currentLevel,
  }) {
    return ProgressionState(
      levels: levels ?? this.levels,
      unlockedWorlds: unlockedWorlds ?? this.unlockedWorlds,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }
}
