class DateService {
  /// Returns the current date and time.
  DateTime now() => DateTime.now();

  /// Returns the date key for today (e.g. '2026-08-20')
  String getTodayDateKey() {
    final dt = now();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Checks if the given dateKey matches today.
  bool isToday(String dateKey) {
    return dateKey == getTodayDateKey();
  }
}
