import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/blocks/blocks.dart';

void main() {
  group('BlockFactory Tests', () {
    test('Create blocks of all initial colors', () {
      final red = BlockFactory.createBlock(color: BlockColor.red, position: const Position(0, 0));
      final green = BlockFactory.createBlock(color: BlockColor.green, position: const Position(0, 1));
      final blue = BlockFactory.createBlock(color: BlockColor.blue, position: const Position(0, 2));
      final yellow = BlockFactory.createBlock(color: BlockColor.yellow, position: const Position(0, 3));
      final purple = BlockFactory.createBlock(color: BlockColor.purple, position: const Position(0, 4));

      expect(red.color, BlockColor.red);
      expect(green.color, BlockColor.green);
      expect(blue.color, BlockColor.blue);
      expect(yellow.color, BlockColor.yellow);
      expect(purple.color, BlockColor.purple);

      // Verify IDs are unique
      final ids = {red.id, green.id, blue.id, yellow.id, purple.id};
      expect(ids.length, 5);

      // Verify defaults
      expect(red.type, BlockType.normal);
      expect(red.position, const Position(0, 0));
      expect(red.isSelected, isFalse);
      expect(red.isLocked, isFalse);
    });

    test('Selected and locked states representable', () {
      var block = BlockFactory.createBlock(color: BlockColor.blue, position: const Position(1, 1));
      block = block.copyWith(isSelected: true, isLocked: true);

      expect(block.isSelected, isTrue);
      expect(block.isLocked, isTrue);
    });

    test('Random allowed color generation', () {
      final allowedColors = [BlockColor.red, BlockColor.green];
      
      final block1 = BlockFactory.createRandomBlock(allowedColors: allowedColors, position: const Position(0, 0));
      final block2 = BlockFactory.createRandomBlock(allowedColors: allowedColors, position: const Position(0, 1));
      
      expect(allowedColors.contains(block1.color), isTrue);
      expect(allowedColors.contains(block2.color), isTrue);
      expect(block1.id, isNot(equals(block2.id)));
    });

    test('Empty color list handles safely', () {
      final block = BlockFactory.createRandomBlock(allowedColors: [], position: const Position(0, 0));
      // Should not crash, and should default to something (e.g. red)
      expect(block.color, isNotNull);
    });
  });
}
