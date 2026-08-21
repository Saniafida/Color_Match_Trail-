class FeedbackConfig {
  // Animation Durations
  static const Duration popDuration = Duration(milliseconds: 300);
  static const Duration floatDuration = Duration(milliseconds: 800);
  static const Duration overlayEntranceDuration = Duration(milliseconds: 400);

  // Match Thresholds
  static const int minBigMatch = 4;
  static const int thresholdGreat = 5;
  static const int thresholdAmazing = 6;

  // Text popups are explicitly disabled (transformation is the celebration)
  static String getMatchText(int length) {
    return "";
  }
}
