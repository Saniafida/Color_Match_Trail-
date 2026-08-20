import 'package:flutter/material.dart';
import '../../models/booster.dart';

enum BoosterActivationStyle {
  instant,
  targeted,
}

class BoosterDefinition {
  final BoosterType type;
  final String name;
  final String description;
  final IconData icon;
  final BoosterActivationStyle activationStyle;
  final int moveCost;
  final int maxInventory;
  final bool allowedInMoveLevels;
  final bool allowedInTimeLevels;

  const BoosterDefinition({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.activationStyle,
    this.moveCost = 0,
    this.maxInventory = 99,
    this.allowedInMoveLevels = true,
    this.allowedInTimeLevels = true,
  });

  static const Map<BoosterType, BoosterDefinition> registry = {
    BoosterType.hammer: BoosterDefinition(
      type: BoosterType.hammer,
      name: "Hammer",
      description: "Smashes a single block.",
      icon: Icons.hardware, // Placeholder icon
      activationStyle: BoosterActivationStyle.targeted,
      moveCost: 0,
    ),
    BoosterType.shuffle: BoosterDefinition(
      type: BoosterType.shuffle,
      name: "Shuffle",
      description: "Rearranges all blocks.",
      icon: Icons.shuffle,
      activationStyle: BoosterActivationStyle.instant,
      moveCost: 0,
    ),
    BoosterType.rowClear: BoosterDefinition(
      type: BoosterType.rowClear,
      name: "Line Blast",
      description: "Clears an entire row.",
      icon: Icons.swap_horiz,
      activationStyle: BoosterActivationStyle.targeted,
      moveCost: 0,
    ),
    BoosterType.colorClear: BoosterDefinition(
      type: BoosterType.colorClear,
      name: "Color Bomb",
      description: "Clears all blocks of the selected color.",
      icon: Icons.color_lens,
      activationStyle: BoosterActivationStyle.targeted,
      moveCost: 0,
    ),
    BoosterType.extraMoves: BoosterDefinition(
      type: BoosterType.extraMoves,
      name: "+5 Moves",
      description: "Adds 5 extra moves.",
      icon: Icons.add_circle_outline,
      activationStyle: BoosterActivationStyle.instant,
      moveCost: 0,
      allowedInTimeLevels: false,
    ),
  };
}
