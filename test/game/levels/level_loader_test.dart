import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/levels/level_loader.dart';

void main() {
  group('LevelLoader', () {
    late LevelLoader loader;

    setUp(() {
      loader = LevelLoader();
    });

    test('loads valid JSON level correctly', () {
      const jsonStr = '''
      {
        "id": 1,
        "version": 1,
        "board": {
          "rows": 6,
          "columns": 6
        },
        "movesLimit": 25,
        "colors": [
          "red",
          "blue",
          "green",
          "yellow"
        ]
      }
      ''';

      final level = loader.loadFromJsonString(jsonStr);

      expect(level.id, 1);
      expect(level.version, 1);
      expect(level.boardConfig.rows, 6);
      expect(level.boardConfig.columns, 6);
      expect(level.movesLimit, 25);
      expect(level.colorConfig?.availableColors.length, 4);
    });

    test('throws StateError for invalid JSON level', () {
      const jsonStr = '''
      {
        "id": 999999,
        "board": {
          "rows": 0,
          "columns": 6
        },
        "movesLimit": 25,
        "colors": [
          "red"
        ]
      }
      ''';

      expect(() => loader.loadFromJsonString(jsonStr), throwsStateError);
    });
  });
}
