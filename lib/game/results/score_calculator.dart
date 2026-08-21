class FinalScoreCalculator {
  static const int scorePerRemainingMove = 50;
  static const int largeBlastBonus = 200;

  static int calculateBonusScore({
    required int remainingMoves,
    required int largestBlast,
    required int maxCombo,
  }) {
    int bonus = 0;
    
    // Remaining moves bonus
    if (remainingMoves > 0) {
      bonus += remainingMoves * scorePerRemainingMove;
    }

    // Large blast bonus
    if (largestBlast >= 7) {
      bonus += largeBlastBonus;
    }

    // Combo bonus (if maxCombo is significantly high)
    if (maxCombo >= 5) {
      bonus += (maxCombo * 20);
    }

    return bonus;
  }

  static int calculateFinalScore({
    required int baseScore,
    required int bonusScore,
  }) {
    return baseScore + bonusScore;
  }
}
