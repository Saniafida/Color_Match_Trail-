class LowTimeEvent {
  final int remainingSeconds;
  const LowTimeEvent(this.remainingSeconds);
}

class TimerTimeoutEvent {
  const TimerTimeoutEvent();
}

class TimerTickEvent {
  final int remainingSeconds;
  final int elapsedSeconds;
  const TimerTickEvent({
    required this.remainingSeconds,
    required this.elapsedSeconds,
  });
}
