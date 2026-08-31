import '../../models/models.dart';

class BoosterConfig {
  static const int defaultHammerInventory = 3;
  static const int defaultShuffleInventory = 2;
  static const int defaultRowClearInventory = 2;
  static const int defaultColorClearInventory = 2;
  static const int defaultAreaBlastInventory = 2;
  static const int defaultExtraMovesInventory = 2;

  static BoosterInventory getDefaultInventory() {
    return const BoosterInventory(quantities: {
      BoosterType.hammer: defaultHammerInventory,
      BoosterType.shuffle: defaultShuffleInventory,
      BoosterType.rowClear: defaultRowClearInventory,
      BoosterType.colorClear: defaultColorClearInventory,
      BoosterType.areaBlast: defaultAreaBlastInventory,
      BoosterType.extraMoves: defaultExtraMovesInventory,
    });
  }
}
