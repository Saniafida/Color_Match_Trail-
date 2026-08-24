import '../../models/models.dart';

class TileStackLevel {
  final int levelNumber;
  final int moves;
  final int pegCount;
  final int maxPegCapacity;
  final int matchRequired; // e.g. 4
  final Map<BlockColor, int> goals; // target count to clear
  final List<List<BlockColor>> initialPegs;
  final List<BlockColor> tileBag;

  const TileStackLevel({
    required this.levelNumber,
    required this.moves,
    this.pegCount = 6,
    this.maxPegCapacity = 4,
    this.matchRequired = 4,
    required this.goals,
    required this.initialPegs,
    required this.tileBag,
  });
}
