import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/level.dart';
import 'package:color_match_trail/models/block.dart';
import 'package:color_match_trail/game/levels/board_config.dart';
import 'package:color_match_trail/game/levels/level_color_config.dart';
import 'package:color_match_trail/game/levels/level_validator.dart';

void main() {
  group('LevelValidator', () {
    late LevelValidator validator;

    setUp(() {
      validator = LevelValidator();
    });

    test('valid level passes validation', () {
      final level = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: 6),
        movesLimit: 25,
        colorConfig: const LevelColorConfig(
          availableColors: [BlockColor.red, BlockColor.blue, BlockColor.green],
        ),
      );

      final result = validator.validate(level);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('invalid rows fails validation', () {
      final level = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 0, columns: 6),
        movesLimit: 25,
        colorConfig: const LevelColorConfig(
          availableColors: [BlockColor.red, BlockColor.blue, BlockColor.green],
        ),
      );

      final result = validator.validate(level);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Board rows must be greater than 0.'));
    });

    test('invalid columns fails validation', () {
      final level = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: -1),
        movesLimit: 25,
        colorConfig: const LevelColorConfig(
          availableColors: [BlockColor.red, BlockColor.blue, BlockColor.green],
        ),
      );

      final result = validator.validate(level);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Board columns must be greater than 0.'));
    });

    test('empty colors fails validation', () {
      final level = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: 6),
        movesLimit: 25,
        colorConfig: const LevelColorConfig(
          availableColors: [],
        ),
      );

      final result = validator.validate(level);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Level must configure at least 3 available colors.'));
    });

    test('invalid moves fails validation', () {
      final level = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: 6),
        movesLimit: 0,
        colorConfig: const LevelColorConfig(
          availableColors: [BlockColor.red, BlockColor.blue, BlockColor.green],
        ),
      );

      final result = validator.validate(level);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('movesLimit must be greater than 0 if provided.'));
    });
  });
}
