class FeedbackConfig {
  // Animation Durations
  static const Duration popDuration = Duration(milliseconds: 300);
  static const Duration floatDuration = Duration(milliseconds: 800);
  static const Duration overlayEntranceDuration = Duration(milliseconds: 400);

  // Match Thresholds
  static const int minBigMatch = 4;
  static const int thresholdGreat = 5;
  static const int thresholdAmazing = 6;

  // Strings
  static String getMatchText(int length) {
    if (length >= thresholdAmazing) return "AMAZING!";
    if (length >= thresholdGreat) return "GREAT!";
    if (length >= minBigMatch) return "GOOD!";
    return "";
  }
}
