enum TimerMode {
  none,
  countdown,
}

class TimerState {
  final TimerMode mode;
  final int remainingSeconds;
  final int elapsedSeconds;
  final bool isLowTime;
  final bool isRunning;

  const TimerState({
    required this.mode,
    this.remainingSeconds = 0,
    this.elapsedSeconds = 0,
    this.isLowTime = false,
    this.isRunning = false,
  });

  TimerState copyWith({
    TimerMode? mode,
    int? remainingSeconds,
    int? elapsedSeconds,
    bool? isLowTime,
    bool? isRunning,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isLowTime: isLowTime ?? this.isLowTime,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
