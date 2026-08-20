enum MoveMode {
  limitedMoves,
  unlimitedMoves
}

class MoveState {
  final MoveMode mode;
  final int remainingMoves;
  final int maxMoves;
  final bool isLowMoves;

  const MoveState({
    required this.mode,
    required this.remainingMoves,
    required this.maxMoves,
    this.isLowMoves = false,
  });
  
  MoveState copyWith({
    MoveMode? mode,
    int? remainingMoves,
    int? maxMoves,
    bool? isLowMoves,
  }) {
    return MoveState(
      mode: mode ?? this.mode,
      remainingMoves: remainingMoves ?? this.remainingMoves,
      maxMoves: maxMoves ?? this.maxMoves,
      isLowMoves: isLowMoves ?? this.isLowMoves,
    );
  }
}
