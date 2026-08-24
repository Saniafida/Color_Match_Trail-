import 'dart:math';

/// Calculates Player Level based on accumulated XP.
class PlayerXPManager {
  static const int _baseXpRequirement = 1000;
  static const double _xpMultiplier = 1.15;
  static const int _maxLevel = 100;

  /// Returns the required total XP to reach [level].
  static int getXpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    if (level > _maxLevel) return getXpRequiredForLevel(_maxLevel);
    
    // Simple exponential curve: Total XP = Base * (Multiplier ^ (Level - 1))
    double req = _baseXpRequirement * pow(_xpMultiplier, level - 2).toDouble();
    // Add previous levels requirement to make it cumulative
    return getXpRequiredForLevel(level - 1) + req.round();
  }

  /// Calculates the current player level given a total XP amount.
  static int calculateLevel(int totalXp) {
    int level = 1;
    while (level < _maxLevel) {
      if (totalXp < getXpRequiredForLevel(level + 1)) {
        break;
      }
      level++;
    }
    return level;
  }
}
