import 'dart:async';
import 'package:flutter/foundation.dart';
import 'security_event_logger.dart';

/// Centralized time source for the game.
/// Detects suspicious clock jumps and ensures timers rely on a consistent source.
class GameTimeService {
  final SecurityEventLogger _logger;
  
  DateTime? _lastKnownTime;
  Timer? _ticker;

  /// Tolerance for clock jumps (e.g., timezone changes). If clock jumps forward
  /// by more than 2 days without a network sync, flag it.
  static const Duration _jumpTolerance = Duration(days: 2);

  GameTimeService(this._logger);

  void initialize() {
    _lastKnownTime = DateTime.now();
    _ticker = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTimeProgression();
    });
  }

  void dispose() {
    _ticker?.cancel();
  }

  /// Always use this instead of DateTime.now() for game mechanics.
  DateTime get now {
    _checkTimeProgression();
    return DateTime.now();
  }

  void _checkTimeProgression() {
    final current = DateTime.now();
    if (_lastKnownTime != null) {
      final delta = current.difference(_lastKnownTime!);
      
      // If time went backwards by more than a day (clock rollback attempt)
      if (delta.isNegative && delta.abs() > const Duration(days: 1)) {
        if (kDebugMode) print('Suspicious clock rollback detected!');
        _logger.logClockAnomaly(_lastKnownTime!.millisecondsSinceEpoch, current.millisecondsSinceEpoch);
      }
      
      // If time went forwards massively (e.g. fast forwarding to get daily rewards)
      if (delta > _jumpTolerance) {
        if (kDebugMode) print('Suspicious clock fast-forward detected!');
        _logger.logClockAnomaly(_lastKnownTime!.millisecondsSinceEpoch, current.millisecondsSinceEpoch);
      }
    }
    _lastKnownTime = current;
  }
}
