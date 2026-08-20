import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'move_state.dart';
import 'move_event.dart';

class MoveController extends ChangeNotifier {
  MoveState _state = const MoveState(
    mode: MoveMode.unlimitedMoves,
    remainingMoves: 0,
    maxMoves: 0,
  );

  MoveState get state => _state;
  int get currentMoves => _state.remainingMoves;
  bool get hasMoves => _state.mode == MoveMode.unlimitedMoves || _state.remainingMoves > 0;

  final StreamController<MoveConsumedEvent> _consumedController = StreamController<MoveConsumedEvent>.broadcast(sync: true);
  Stream<MoveConsumedEvent> get onMoveConsumed => _consumedController.stream;

  final StreamController<LowMovesEvent> _lowMovesController = StreamController<LowMovesEvent>.broadcast(sync: true);
  Stream<LowMovesEvent> get onLowMoves => _lowMovesController.stream;

  final int lowMovesThreshold;

  MoveController({
    this.lowMovesThreshold = 3,
  });

  void initialize(int? maxMoves) {
    if (maxMoves == null) {
      _state = const MoveState(
        mode: MoveMode.unlimitedMoves,
        remainingMoves: 0,
        maxMoves: 0,
      );
    } else {
      _state = MoveState(
        mode: MoveMode.limitedMoves,
        remainingMoves: math.max(0, maxMoves),
        maxMoves: math.max(0, maxMoves),
        isLowMoves: maxMoves <= lowMovesThreshold,
      );
    }
    notifyListeners();
  }

  void resetMoves() {
    if (_state.mode == MoveMode.limitedMoves) {
      _state = _state.copyWith(
        remainingMoves: _state.maxMoves,
        isLowMoves: _state.maxMoves <= lowMovesThreshold,
      );
      notifyListeners();
    }
  }

  void consumeMove({MoveSource source = MoveSource.playerMatch}) {
    if (_state.mode == MoveMode.unlimitedMoves) return;
    if (_state.remainingMoves <= 0) return;

    final previous = _state.remainingMoves;
    final remaining = previous - 1;
    
    final wasLow = _state.isLowMoves;
    final isNowLow = remaining <= lowMovesThreshold;

    _state = _state.copyWith(
      remainingMoves: remaining,
      isLowMoves: isNowLow,
    );

    _consumedController.add(MoveConsumedEvent(
      previousMoves: previous,
      remainingMoves: remaining,
      source: source,
    ));

    if (isNowLow && !wasLow) {
      _lowMovesController.add(LowMovesEvent(remainingMoves: remaining));
    }

    notifyListeners();
  }

  void addMoves(int amount) {
    if (_state.mode == MoveMode.unlimitedMoves || amount <= 0) return;

    final newAmount = _state.remainingMoves + amount;
    final isNowLow = newAmount <= lowMovesThreshold;

    _state = _state.copyWith(
      remainingMoves: newAmount,
      isLowMoves: isNowLow,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _consumedController.close();
    _lowMovesController.close();
    super.dispose();
  }
}
