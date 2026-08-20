import 'package:flutter/foundation.dart';

/// Represents the deployment environment the game is running in.
enum DataEnvironment {
  /// Local development build — dev overrides may be active.
  development,

  /// Profile/staging build — performance profiling enabled.
  staging,

  /// Release/production build — all dev overrides disabled.
  production,
}

extension DataEnvironmentExtension on DataEnvironment {
  /// Derives the current environment from Flutter's compilation mode.
  static DataEnvironment get current {
    if (kReleaseMode) return DataEnvironment.production;
    if (kProfileMode) return DataEnvironment.staging;
    return DataEnvironment.development;
  }

  bool get isDevelopment => this == DataEnvironment.development;
  bool get isProduction => this == DataEnvironment.production;
  bool get isStaging => this == DataEnvironment.staging;
}
