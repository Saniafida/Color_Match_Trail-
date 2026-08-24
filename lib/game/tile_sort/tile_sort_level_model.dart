import '../../models/models.dart';

enum TubeTheme {
  crystalClassic,
  potionFlask,
  royalEnchanted,
}

class TileSortLevel {
  final int levelNumber;
  final int capacity;
  final int moves;
  final List<List<BlockColor>> initialTubes;
  final List<BlockColor> activeColors;
  final TubeTheme theme;
  final String shelfName;

  const TileSortLevel({
    required this.levelNumber,
    required this.capacity,
    required this.moves,
    required this.initialTubes,
    required this.activeColors,
    this.theme = TubeTheme.crystalClassic,
    this.shelfName = 'Wooden Garden Shelf',
  });
}
