import 'block.dart';
import 'booster.dart';

enum GoalType {
  clearColor,
  clearBlocks,
  score,
  activateSpecial,
  createSpecial,
  reachCascade,
  destroySpecial,
  useBooster,
  // Future types: collectItem, surviveMoves, clearObstacle, etc.
}

class GoalDefinition {
  final String id;
  final GoalType type;
  final int targetAmount;
  final BlockColor? color;
  final SpecialBlockType? specialType;
  final BoosterType? boosterType;
  final bool isOptional;
  final Map<String, dynamic>? displayData;

  const GoalDefinition({
    required this.id,
    required this.type,
    required this.targetAmount,
    this.color,
    this.specialType,
    this.boosterType,
    this.isOptional = false,
    this.displayData,
  }) : assert(targetAmount > 0, 'targetAmount must be positive');

  GoalDefinition copyWith({
    String? id,
    GoalType? type,
    int? targetAmount,
    BlockColor? color,
    SpecialBlockType? specialType,
    BoosterType? boosterType,
    bool? isOptional,
    Map<String, dynamic>? displayData,
  }) {
    return GoalDefinition(
      id: id ?? this.id,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      color: color ?? this.color,
      specialType: specialType ?? this.specialType,
      boosterType: boosterType ?? this.boosterType,
      isOptional: isOptional ?? this.isOptional,
      displayData: displayData ?? this.displayData,
    );
  }
}
