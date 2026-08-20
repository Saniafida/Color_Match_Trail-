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

  /// Safely returns a random color from the allowed list.
  static BlockColor getRandomColor(List<BlockColor> allowedColors) {
    if (allowedColors.isEmpty) {
      // Fallback in case of empty allowed colors to prevent crashing
      return BlockColor.red;
    }
    final index = _random.nextInt(allowedColors.length);
    return allowedColors[index];
  }

  /// Creates a block choosing a random color from the allowed list.
  static Block createRandomBlock({
    required List<BlockColor> allowedColors,
    required Position position,
    BlockType type = BlockType.normal,
  }) {
    final color = getRandomColor(allowedColors);
    return createBlock(color: color, position: position, type: type);
  }
}
