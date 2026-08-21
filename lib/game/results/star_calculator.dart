class StarCalculator {
  /// Calculates stars (0-3) based on the score and thresholds.
  /// Example thresholds: [1000, 2000, 3000]
  static int calculateStars(int score, List<int> thresholds) {
    if (thresholds.isEmpty) return 3; // Default to 3 if no config
    
    int stars = 0;
    for (int i = 0; i < thresholds.length; i++) {
      if (score >= thresholds[i]) {
        stars = i + 1;
      } else {
        break; // Stop at the highest earned star
      }
    }
    
    return stars.clamp(0, 3);
  }
}
