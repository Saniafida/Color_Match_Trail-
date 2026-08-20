import 'dart:async';
import 'package:flutter/foundation.dart';
import 'timer_state.dart';
import 'timer_event.dart';
import 'dart:math' as math;

class TimerController extends ChangeNotifier {
  TimerState _state = const TimerState(mode: TimerMode.none);
  TimerState get state => _state;
  
  Timer? _systemTimer;
  int? _timeLimit;
  final int lowTimeThreshold;

  final StreamController<LowTimeEvent> _lowTimeController = StreamController<LowTimeEvent>.broadcast(sync: true);
  Stream<LowTimeEvent> get onLowTime => _lowTimeController.stream;

  final StreamController<TimerTimeoutEvent> _timeoutController = StreamController<TimerTimeoutEvent>.broadcast(sync: true);
  Stream<TimerTimeoutEvent> get onTimeout => _timeoutController.stream;
  
  final StreamController<TimerTickEvent> _tickController = StreamController<TimerTickEvent>.broadcast(sync: true);
  Stream<TimerTickEvent> get onTick => _tickController.stream;

  TimerController({this.lowTimeThreshold = 10});

  void initialize(int? timeLimitSeconds) {
    stop();
    _timeLimit = timeLimitSeconds;
    if (timeLimitSeconds == null) {
      _state = const TimerState(mode: TimerMode.none);
    } else {
      _state = TimerState(
        mode: TimerMode.countdown,
        remainingSeconds: math.max(0, timeLimitSeconds),
        elapsedSeconds: 0,
        isLowTime: timeLimitSeconds <= lowTimeThreshold,
        isRunning: false,
      );
    }
    notifyListeners();
  }

  void start() {
    if (_state.mode == TimerMode.none || _state.isRunning) return;
    if (_state.remainingSeconds <= 0) return;

    _state = _state.copyWith(isRunning: true);
    notifyListeners();
    
    _systemTimer?.cancel();
    _systemTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!_state.isRunning) return;
    
    final newRemaining = _state.remainingSeconds - 1;
    final newElapsed = _state.elapsedSeconds + 1;
    
    if (newRemaining <= 0) {
      timer.cancel();
      _state = _state.copyWith(
        remainingSeconds: 0,
        elapsedSeconds: newElapsed,
        isRunning: false,
        isLowTime: true,
      );
      _tickController.add(TimerTickEvent(remainingSeconds: 0, elapsedSeconds: newElapsed));
      _timeoutController.add(const TimerTimeoutEvent());
      notifyListeners();
      return;
    }

    final wasLow = _state.isLowTime;
    final isNowLow = newRemaining <= lowTimeThreshold;

    _state = _state.copyWith(
      remainingSeconds: newRemaining,
      elapsedSeconds: newElapsed,
      isLowTime: isNowLow,
    );
    
    _tickController.add(TimerTickEvent(
      remainingSeconds: newRemaining, 
      elapsedSeconds: newElapsed
    ));
    
    if (isNowLow && !wasLow) {
      _lowTimeController.add(LowTimeEvent(newRemaining));
    }
    
    notifyListeners();
  }

  void pause() {
    if (_state.isRunning) {
      _systemTimer?.cancel();
      _state = _state.copyWith(isRunning: false);
      notifyListeners();
    }
  }

  void resume() {
    if (_state.mode == TimerMode.countdown && !_state.isRunning && _state.remainingSeconds > 0) {
      start();
    }
  }

  void stop() {
    _systemTimer?.cancel();
    if (_state.isRunning) {
      _state = _state.copyWith(isRunning: false);
      notifyListeners();
    }
  }

  void reset() {
    stop();
    if (_timeLimit != null) {
      _state = TimerState(
        mode: TimerMode.countdown,
        remainingSeconds: math.max(0, _timeLimit!),
        elapsedSeconds: 0,
        isLowTime: _timeLimit! <= lowTimeThreshold,
        isRunning: false,
      );
      notifyListeners();
    }
  }
  
  void addTime(int seconds) {
    if (_state.mode == TimerMode.none || seconds <= 0) return;
    
    final newRemaining = _state.remainingSeconds + seconds;
    final isNowLow = newRemaining <= lowTimeThreshold;
    
    _state = _state.copyWith(
      remainingSeconds: newRemaining,
      isLowTime: isNowLow,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _systemTimer?.cancel();
    _lowTimeController.close();
    _timeoutController.close();
    _tickController.close();
    super.dispose();
  }
}
