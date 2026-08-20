class WorldProgress {
  final String worldId;
  final bool unlocked;
  final int completedLevels;
  final int totalLevels;
  final int earnedStars;
  final int totalStars;

  const WorldProgress({
    required this.worldId,
    required this.unlocked,
    required this.completedLevels,
    required this.totalLevels,
    required this.earnedStars,
    required this.totalStars,
  });

  double get completionPercentage {
    if (totalLevels == 0) return 0.0;
    return (completedLevels / totalLevels).clamp(0.0, 1.0);
  }

  bool get isCompleted => completedLevels >= totalLevels && totalLevels > 0;
}
