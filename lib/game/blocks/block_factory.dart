import 'dart:math';
import '../../models/models.dart';

class BlockFactory {
  static int _counter = 0;
  static final _random = Random();

  /// Generates a globally unique ID for a block.
  static String generateId() {
    _counter++;
    return 'block_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }

  /// Creates a specific block with a predefined color.
  static Block createBlock({
    required BlockColor color,
    required Position position,
    BlockType type = BlockType.normal,
  }) {
    return Block(
      id: generateId(),
      color: color,
      type: type,
      position: position,
    );
  }

  /// Safely returns a random color from the allowed list, with configurable bias towards target colors.
  static BlockColor getRandomColor(
    List<BlockColor> allowedColors, {
    List<BlockColor>? targetColors,
    double targetBias = 0.60,
    Random? rng,
  }) {
    if (allowedColors.isEmpty) {
      // Fallback in case of empty allowed colors to prevent crashing
      return BlockColor.red;
    }
    final r = rng ?? _random;

    if (targetColors != null && targetColors.isNotEmpty) {
      final validTargets = targetColors.where((c) => allowedColors.contains(c)).toList();
      if (validTargets.isNotEmpty && r.nextDouble() < targetBias) {
        return validTargets[r.nextInt(validTargets.length)];
      }
    }

    final index = r.nextInt(allowedColors.length);
    return allowedColors[index];
  }

  /// Creates a block choosing a random color from the allowed list with target bias.
  static Block createRandomBlock({
    required List<BlockColor> allowedColors,
    List<BlockColor>? targetColors,
    double targetBias = 0.60,
    required Position position,
    BlockType type = BlockType.normal,
    Random? rng,
  }) {
    final color = getRandomColor(
      allowedColors,
      targetColors: targetColors,
      targetBias: targetBias,
      rng: rng,
    );
    return createBlock(color: color, position: position, type: type);
  }
}
