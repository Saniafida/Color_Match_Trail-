import 'dart:async';

class RetryController {
  final int maxRetries;
  final Duration baseDelay;
  int _currentAttempt = 0;

  RetryController({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
  });

  bool get canRetry => _currentAttempt < maxRetries;
  int get currentAttempt => _currentAttempt;

  Future<bool> retry(FutureOr<void> Function() action) async {
    if (!canRetry) return false;

    _currentAttempt++;
    
    // Exponential backoff
    final delay = baseDelay * _currentAttempt;
    await Future.delayed(delay);

    try {
      await action();
      reset(); // Reset on success
      return true;
    } catch (e) {
      return false; // Action failed again
    }
  }

  void reset() {
    _currentAttempt = 0;
  }
}
