import 'dart:math';
import '../../models/models.dart';
import 'tile_stack_level_model.dart';

class TileStackLevelGenerator {
  static final Random _rng = Random();

  static TileStackLevel getLevel(int levelNumber) {
    switch (levelNumber) {
      case 1:
        // LEVEL 1: Very Easy tutorial (2 colors, 4 pegs, match 4)
        return const TileStackLevel(
          levelNumber: 1,
          moves: 15,
          pegCount: 4,
          maxPegCapacity: 4,
          matchRequired: 4,
          goals: {
            BlockColor.red: 4,
            BlockColor.yellow: 4,
          },
          initialPegs: [
            [BlockColor.red, BlockColor.red, BlockColor.red],
            [BlockColor.yellow, BlockColor.yellow, BlockColor.yellow],
            [],
            [],
          ],
          tileBag: [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.red,
            BlockColor.yellow,
          ],
        );

      case 2:
        // LEVEL 2: Easy (3 colors, 5 pegs)
        return const TileStackLevel(
          levelNumber: 2,
          moves: 20,
          pegCount: 5,
          maxPegCapacity: 4,
          matchRequired: 4,
          goals: {
            BlockColor.red: 4,
            BlockColor.yellow: 4,
            BlockColor.blue: 4,
          },
          initialPegs: [
            [BlockColor.red, BlockColor.red],
            [BlockColor.yellow, BlockColor.yellow, BlockColor.yellow],
            [BlockColor.blue, BlockColor.blue],
            [],
            [],
          ],
          tileBag: [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.red,
            BlockColor.blue,
          ],
        );

      case 3:
        // LEVEL 3: Medium (4 colors, 5 pegs)
        return const TileStackLevel(
          levelNumber: 3,
          moves: 22,
          pegCount: 5,
          maxPegCapacity: 4,
          matchRequired: 4,
          goals: {
            BlockColor.red: 8,
            BlockColor.yellow: 4,
            BlockColor.blue: 4,
            BlockColor.green: 4,
          },
          initialPegs: [
            [BlockColor.red, BlockColor.red, BlockColor.red],
            [BlockColor.yellow, BlockColor.yellow],
            [BlockColor.blue, BlockColor.blue, BlockColor.blue],
            [BlockColor.green, BlockColor.green],
            [],
          ],
          tileBag: [
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.green,
            BlockColor.blue,
            BlockColor.red,
          ],
        );

      case 4:
      case 5:
        // LEVEL 5 (Exact Reference Screenshot Layout)
        return const TileStackLevel(
          levelNumber: 5,
          moves: 25,
          pegCount: 6,
          maxPegCapacity: 4,
          matchRequired: 4,
          goals: {
            BlockColor.red: 8,
            BlockColor.yellow: 8,
            BlockColor.blue: 8,
            BlockColor.green: 8,
          },
          initialPegs: [
            [BlockColor.purple, BlockColor.purple, BlockColor.purple],
            [BlockColor.yellow, BlockColor.yellow, BlockColor.yellow],
            [BlockColor.red, BlockColor.red],
            [BlockColor.blue, BlockColor.blue, BlockColor.blue],
            [BlockColor.green, BlockColor.green, BlockColor.green],
            [BlockColor.purple],
          ],
          tileBag: [
            BlockColor.purple,
            BlockColor.yellow,
            BlockColor.red,
            BlockColor.blue,
            BlockColor.green,
            BlockColor.red,
            BlockColor.yellow,
            BlockColor.blue,
            BlockColor.green,
          ],
        );

      default:
        // Procedural generator for higher levels
        return _generateProceduralLevel(levelNumber);
    }
  }

  static TileStackLevel _generateProceduralLevel(int levelNumber) {
    final int colorCount = (levelNumber < 10) ? 4 : 5;
    final int pegCount = 6;
    final int maxPegCapacity = 4;
    final int matchRequired = 4;

    final availableColors = [
      BlockColor.red,
      BlockColor.yellow,
      BlockColor.blue,
      BlockColor.green,
      BlockColor.purple,
    ].sublist(0, colorCount);

    final Map<BlockColor, int> goals = {};
    for (final c in availableColors) {
      goals[c] = (levelNumber < 15) ? 8 : 12;
    }

    final List<List<BlockColor>> pegs = List.generate(pegCount, (_) => <BlockColor>[]);
    for (int p = 0; p < pegCount; p++) {
      final color = availableColors[p % colorCount];
      final height = _rng.nextInt(3) + 1;
      for (int h = 0; h < height; h++) {
        pegs[p].add(color);
      }
    }

    final List<BlockColor> bag = [];
    for (int i = 0; i < 40; i++) {
      bag.add(availableColors[_rng.nextInt(colorCount)]);
    }

    final moves = 20 + (levelNumber % 10);

    return TileStackLevel(
      levelNumber: levelNumber,
      moves: moves,
      pegCount: pegCount,
      maxPegCapacity: maxPegCapacity,
      matchRequired: matchRequired,
      goals: goals,
      initialPegs: pegs,
      tileBag: bag,
    );
  }
}
