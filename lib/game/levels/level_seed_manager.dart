class LevelSeedManager {
  /// Computes a deterministic integer seed from a level ID string and optional base seed.
  static int getSeedForLevel(String levelId, {int baseSeed = 1337}) {
    int hash = baseSeed;
    for (int i = 0; i < levelId.length; i++) {
      hash = (hash * 31 + levelId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }
}
