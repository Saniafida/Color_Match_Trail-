class WorldProgress {
  final String worldId;
  final bool unlocked;
  final bool completed;
  final int completedLevels;
  final int totalLevels;
  final int stars;
  final int maxStars;

  const WorldProgress({
    required this.worldId,
    required this.unlocked,
    required this.completed,
    required this.completedLevels,
    required this.totalLevels,
    required this.stars,
    required this.maxStars,
  });

  /// Backwards compatibility aliases
  int get earnedStars => stars;
  int get totalStars => maxStars;
  bool get isCompleted => completed || (completedLevels >= totalLevels && totalLevels > 0);

  double get completionPercentage {
    if (totalLevels == 0) return 0.0;
    return (completedLevels / totalLevels).clamp(0.0, 1.0);
  }

  factory WorldProgress.fromJson(Map<String, dynamic> json) {
    return WorldProgress(
      worldId: json['worldId'] as String? ?? '',
      unlocked: json['unlocked'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      completedLevels: json['completedLevels'] as int? ?? 0,
      totalLevels: json['totalLevels'] as int? ?? 0,
      stars: json['stars'] as int? ?? json['earnedStars'] as int? ?? 0,
      maxStars: json['maxStars'] as int? ?? json['totalStars'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worldId': worldId,
      'unlocked': unlocked,
      'completed': completed,
      'completedLevels': completedLevels,
      'totalLevels': totalLevels,
      'stars': stars,
      'maxStars': maxStars,
    };
  }

  WorldProgress copyWith({
    bool? unlocked,
    bool? completed,
    int? completedLevels,
    int? totalLevels,
    int? stars,
    int? maxStars,
  }) {
    return WorldProgress(
      worldId: worldId,
      unlocked: unlocked ?? this.unlocked,
      completed: completed ?? this.completed,
      completedLevels: completedLevels ?? this.completedLevels,
      totalLevels: totalLevels ?? this.totalLevels,
      stars: stars ?? this.stars,
      maxStars: maxStars ?? this.maxStars,
    );
  }
}
