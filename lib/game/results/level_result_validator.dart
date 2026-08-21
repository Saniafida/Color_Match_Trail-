class LevelResultValidator {
  /// Validates standard bounds for level result data before allowing a save.
  static bool validate({
    required String levelId,
    required int score,
    required int stars,
    required int movesUsed,
    required int combo,
    required int blast,
  }) {
    if (levelId.isEmpty) return false;
    if (score < 0 || score > 99999999) return false;
    if (stars < 0 || stars > 3) return false;
    if (movesUsed < 0) return false;
    if (combo < 0) return false;
    if (blast < 0) return false;

    return true;
  }
}
