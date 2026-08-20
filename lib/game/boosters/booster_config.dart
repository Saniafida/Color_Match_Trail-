import '../../models/models.dart';

class BoosterConfig {
  static const int defaultHammerInventory = 3;
  static const int defaultShuffleInventory = 2;
  static const int defaultRowClearInventory = 1;
  static const int defaultColorClearInventory = 1;

  static BoosterInventory getDefaultInventory() {
    return const BoosterInventory(quantities: {
      BoosterType.hammer: defaultHammerInventory,
      BoosterType.shuffle: defaultShuffleInventory,
      BoosterType.rowClear: defaultRowClearInventory,
      BoosterType.colorClear: defaultColorClearInventory,
    });
  }
}
