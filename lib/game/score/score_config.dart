class ScoreConfig {
  static const int baseScorePerBlock = 10;

  static double getConnectionMultiplier(int length) {
    if (length < 3) return 0.0;
    if (length == 3) return 1.00;
    if (length == 4) return 1.25;
    if (length == 5) return 1.50;
    if (length == 6) return 1.75;
    return 2.00; // 7+
  }

  static double getCascadeMultiplier(int cascadeLevel) {
    if (cascadeLevel <= 0) return 1.00;
    if (cascadeLevel == 1) return 1.10;
    if (cascadeLevel == 2) return 1.25;
    if (cascadeLevel == 3) return 1.50;
    return 1.75; // 4+
  }

  static const int largeScoreThreshold = 250;
  static const int megaScoreThreshold = 500;
}
