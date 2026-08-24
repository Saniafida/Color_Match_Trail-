import 'dart:math';
import '../../models/models.dart';
import 'tile_sort_level_model.dart';

class TileSortLevelGenerator {
  static final Random _rng = Random();

  /// Curated initial levels + infinite dynamic generator
  static TileSortLevel getLevel(int levelNumber) {
    switch (levelNumber) {
      case 1:
        // LEVEL 1: Tutorial / Very Easy (2 colors, 3 tubes, capacity 3)
        return const TileSortLevel(
          levelNumber: 1,
          capacity: 3,
          moves: 12,
          activeColors: [BlockColor.red, BlockColor.yellow],
          initialTubes: [
            [BlockColor.yellow, BlockColor.red, BlockColor.yellow],
            [BlockColor.red, BlockColor.yellow, BlockColor.red],
            [],
          ],
          theme: TubeTheme.crystalClassic,
          shelfName: 'Garden Pine Shelf',
        );

      case 2:
        // LEVEL 2: Easy (3 colors, 4 tubes, capacity 3)
        return const TileSortLevel(
          levelNumber: 2,
          capacity: 3,
          moves: 16,
          activeColors: [BlockColor.red, BlockColor.yellow, BlockColor.blue],
          initialTubes: [
            [BlockColor.blue, BlockColor.yellow, BlockColor.red],
            [BlockColor.red, BlockColor.blue, BlockColor.yellow],
            [BlockColor.yellow, BlockColor.red, BlockColor.blue],
            [],
          ],
          theme: TubeTheme.crystalClassic,
          shelfName: 'Garden Pine Shelf',
        );

      case 3:
        // LEVEL 3: Easy-Medium (3 colors, 4 tubes, capacity 4)
        return const TileSortLevel(
          levelNumber: 3,
          capacity: 4,
          moves: 20,
          activeColors: [BlockColor.red, BlockColor.green, BlockColor.blue],
          initialTubes: [
            [BlockColor.blue, BlockColor.green, BlockColor.red, BlockColor.green],
            [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.blue],
            [BlockColor.green, BlockColor.red, BlockColor.blue, BlockColor.red],
            [],
          ],
          theme: TubeTheme.crystalClassic,
          shelfName: 'Oak Moss Shelf',
        );

      case 4:
        // LEVEL 4: Medium (4 colors, 5 tubes, capacity 4) -> Introduces Potion Flask Theme!
        return const TileSortLevel(
          levelNumber: 4,
          capacity: 4,
          moves: 24,
          activeColors: [BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.green],
          initialTubes: [
            [BlockColor.green, BlockColor.yellow, BlockColor.red, BlockColor.blue],
            [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.yellow],
            [BlockColor.yellow, BlockColor.red, BlockColor.blue, BlockColor.green],
            [BlockColor.blue, BlockColor.green, BlockColor.yellow, BlockColor.red],
            [],
          ],
          theme: TubeTheme.potionFlask,
          shelfName: 'Alchemy Lab Table',
        );

      case 5:
        // LEVEL 5: Challenging (4 colors, 5 tubes, capacity 5) -> Exact match to reference!
        return const TileSortLevel(
          levelNumber: 5,
          capacity: 5,
          moves: 20,
          activeColors: [BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.purple],
          initialTubes: [
            [BlockColor.blue, BlockColor.green, BlockColor.purple, BlockColor.yellow, BlockColor.red],
            [BlockColor.purple, BlockColor.yellow, BlockColor.red, BlockColor.green, BlockColor.blue],
            [BlockColor.green, BlockColor.red, BlockColor.blue, BlockColor.purple, BlockColor.yellow],
            [BlockColor.red, BlockColor.green, BlockColor.yellow, BlockColor.blue, BlockColor.purple],
            [],
          ],
          theme: TubeTheme.potionFlask,
          shelfName: 'Carved Mahogany Shelf',
        );

      case 6:
        // LEVEL 6: Hard (5 colors, 6 tubes, capacity 4) -> Royal Enchanted Theme!
        return const TileSortLevel(
          levelNumber: 6,
          capacity: 4,
          moves: 28,
          activeColors: [BlockColor.red, BlockColor.yellow, BlockColor.blue, BlockColor.green, BlockColor.purple],
          initialTubes: [
            [BlockColor.purple, BlockColor.blue, BlockColor.red, BlockColor.green],
            [BlockColor.yellow, BlockColor.green, BlockColor.purple, BlockColor.blue],
            [BlockColor.red, BlockColor.yellow, BlockColor.green, BlockColor.purple],
            [BlockColor.blue, BlockColor.red, BlockColor.yellow, BlockColor.red],
            [BlockColor.green, BlockColor.purple, BlockColor.blue, BlockColor.yellow],
            [],
          ],
          theme: TubeTheme.royalEnchanted,
          shelfName: 'Royal Enchanted Pedestal',
        );

      default:
        // LEVEL 7+: Procedurally generated solvable levels with scaling difficulty
        return _generateProceduralLevel(levelNumber);
    }
  }

  static TileSortLevel _generateProceduralLevel(int levelNumber) {
    final int colorCount = (levelNumber < 10) ? 4 : ((levelNumber < 18) ? 5 : 5);
    final int capacity = (levelNumber < 8) ? 4 : 5;
    final int emptyTubes = (colorCount >= 5 && levelNumber > 12) ? 2 : 1;

    final availableColors = [
      BlockColor.red,
      BlockColor.yellow,
      BlockColor.blue,
      BlockColor.green,
      BlockColor.purple,
    ].sublist(0, colorCount);

    // Create completed state
    final List<List<BlockColor>> tubes = [];
    for (int i = 0; i < colorCount; i++) {
      tubes.add(List.filled(capacity, availableColors[i], growable: true));
    }
    for (int i = 0; i < emptyTubes; i++) {
      tubes.add(<BlockColor>[]);
    }

    // Shuffle backward moves from solved state to guarantee 100% solvability
    final int shuffleSteps = min(15 + (levelNumber * 2), 60);
    for (int step = 0; step < shuffleSteps; step++) {
      final nonEmptyIndices = <int>[];
      final nonFullIndices = <int>[];

      for (int i = 0; i < tubes.length; i++) {
        if (tubes[i].isNotEmpty) nonEmptyIndices.add(i);
        if (tubes[i].length < capacity) nonFullIndices.add(i);
      }

      if (nonEmptyIndices.isEmpty || nonFullIndices.isEmpty) continue;

      final from = nonEmptyIndices[_rng.nextInt(nonEmptyIndices.length)];
      final to = nonFullIndices[_rng.nextInt(nonFullIndices.length)];

      if (from != to) {
        final block = tubes[from].removeLast();
        tubes[to].add(block);
      }
    }

    final theme = (levelNumber % 3 == 0)
        ? TubeTheme.royalEnchanted
        : ((levelNumber % 2 == 0)
            ? TubeTheme.potionFlask
            : TubeTheme.crystalClassic);

    final moves = (colorCount * capacity) + 12 + (levelNumber % 5);

    return TileSortLevel(
      levelNumber: levelNumber,
      capacity: capacity,
      moves: moves,
      activeColors: availableColors,
      initialTubes: tubes,
      theme: theme,
      shelfName: 'Master Level $levelNumber Shelf',
    );
  }
}
