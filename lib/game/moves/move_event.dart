enum MoveSource {
  playerMatch,
  booster,
  special
}

class MoveConsumedEvent {
  final int previousMoves;
  final int remainingMoves;
  final MoveSource source;

  const MoveConsumedEvent({
    required this.previousMoves,
    required this.remainingMoves,
    required this.source,
  });
}

class LowMovesEvent {
  final int remainingMoves;

  const LowMovesEvent({
    required this.remainingMoves,
  });
}
