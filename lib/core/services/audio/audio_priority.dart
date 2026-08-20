enum AudioPriority {
  /// Very low importance, easily dropped (e.g. minor UI click)
  low,

  /// Standard game events (e.g. basic match)
  normal,

  /// Important events that should suppress normal audio (e.g. big blast, booster)
  high,

  /// Must play events (e.g. level complete, major reward)
  critical,
}

extension AudioPriorityExtension on AudioPriority {
  int get value {
    switch (this) {
      case AudioPriority.low:
        return 0;
      case AudioPriority.normal:
        return 1;
      case AudioPriority.high:
        return 2;
      case AudioPriority.critical:
        return 3;
    }
  }
}
