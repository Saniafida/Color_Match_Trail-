import 'package:flutter/foundation.dart';

/// Development-only performance logger. Silent in release mode.
class PerformanceLogger {
  static const int _slowFrameThresholdMs = 32; // ~30fps
  static const int _slowLoadThresholdMs = 500;

  void logSlowFrame(Duration frameDuration) {
    if (!kDebugMode) return;
    if (frameDuration.inMilliseconds > _slowFrameThresholdMs) {
      debugPrint(
        '⚠️ [PERF] Slow frame: ${frameDuration.inMilliseconds}ms '
        '(threshold: ${_slowFrameThresholdMs}ms)',
      );
    }
  }

  void logSlowLoad(String label, Duration duration) {
    if (!kDebugMode) return;
    if (duration.inMilliseconds > _slowLoadThresholdMs) {
      debugPrint(
        '⚠️ [PERF] Slow load "$label": ${duration.inMilliseconds}ms',
      );
    }
  }

  void logEvent(String event, {Map<String, dynamic>? details}) {
    if (!kDebugMode) return;
    final detailStr = details != null ? ' $details' : '';
    debugPrint('📊 [PERF] $event$detailStr');
  }

  void logWarning(String message) {
    if (!kDebugMode) return;
    debugPrint('⚠️ [PERF WARNING] $message');
  }
}
