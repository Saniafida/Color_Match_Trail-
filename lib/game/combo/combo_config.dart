class ComboConfig {
  static const Duration comboTimeout = Duration(seconds: 2);

  static double getMultiplier(int comboLevel) {
    if (comboLevel <= 1) return 1.00;
    if (comboLevel == 2) return 1.25;
    if (comboLevel == 3) return 1.50;
    if (comboLevel == 4) return 1.75;
    return 2.00; // 5+
  }
}
