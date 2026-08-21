import '../../models/booster.dart';

enum CombinationResultEffect {
  crossBlast,      // lineBlast + lineBlast
  crossAndArea,    // lineBlast + areaBlast
  largeAreaBlast,  // areaBlast + areaBlast
  boardClearColor, // colorClear + colorClear
  colorLineBlast,  // colorClear + lineBlast
  colorAreaBlast,  // colorClear + areaBlast
  unknown,
}

class BoosterCombinationDefinition {
  final String combinationId;
  final BoosterType boosterA;
  final BoosterType boosterB;
  final CombinationResultEffect resultEffect;
  final bool enabled;

  const BoosterCombinationDefinition({
    required this.combinationId,
    required this.boosterA,
    required this.boosterB,
    required this.resultEffect,
    this.enabled = true,
  });

  bool matches(BoosterType a, BoosterType b) {
    return (boosterA == a && boosterB == b) || (boosterA == b && boosterB == a);
  }

  static const List<BoosterCombinationDefinition> registry = [
    BoosterCombinationDefinition(
      combinationId: "line_line",
      boosterA: BoosterType.rowClear,
      boosterB: BoosterType.rowClear,
      resultEffect: CombinationResultEffect.crossBlast,
    ),
    BoosterCombinationDefinition(
      combinationId: "area_area",
      boosterA: BoosterType.areaBlast,
      boosterB: BoosterType.areaBlast,
      resultEffect: CombinationResultEffect.largeAreaBlast,
    ),
    BoosterCombinationDefinition(
      combinationId: "line_area",
      boosterA: BoosterType.rowClear,
      boosterB: BoosterType.areaBlast,
      resultEffect: CombinationResultEffect.crossAndArea,
    ),
    BoosterCombinationDefinition(
      combinationId: "color_color",
      boosterA: BoosterType.colorClear,
      boosterB: BoosterType.colorClear,
      resultEffect: CombinationResultEffect.boardClearColor,
    ),
    BoosterCombinationDefinition(
      combinationId: "color_line",
      boosterA: BoosterType.colorClear,
      boosterB: BoosterType.rowClear,
      resultEffect: CombinationResultEffect.colorLineBlast,
    ),
    BoosterCombinationDefinition(
      combinationId: "color_area",
      boosterA: BoosterType.colorClear,
      boosterB: BoosterType.areaBlast,
      resultEffect: CombinationResultEffect.colorAreaBlast,
    ),
    BoosterCombinationDefinition(
      combinationId: "hammer_hammer",
      boosterA: BoosterType.hammer,
      boosterB: BoosterType.hammer,
      resultEffect: CombinationResultEffect.crossBlast, 
    ),
  ];

  static BoosterCombinationDefinition? getCombination(BoosterType a, BoosterType b) {
    try {
      return registry.firstWhere((def) => def.enabled && def.matches(a, b));
    } catch (e) {
      return null;
    }
  }
}
