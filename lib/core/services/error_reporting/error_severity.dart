enum ErrorSeverity {
  /// Informational, standard operations, minor hiccups
  info,

  /// Potential issue, but safely handled or ignored
  warning,

  /// Handled exception, game can continue but functionality might be degraded
  nonFatal,

  /// Critical crash, game cannot continue in current state
  fatal,
}
