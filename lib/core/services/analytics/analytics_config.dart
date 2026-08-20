enum AnalyticsEnvironment {
  development,
  staging,
  production,
}

class AnalyticsConfig {
  final bool enabled;
  final bool debug;
  final int batchSize;
  final Duration flushInterval;
  final AnalyticsEnvironment environment;

  const AnalyticsConfig({
    this.enabled = true,
    this.debug = false,
    this.batchSize = 20,
    this.flushInterval = const Duration(seconds: 30),
    this.environment = AnalyticsEnvironment.production,
  });

  /// A default config for development environment
  factory AnalyticsConfig.development() {
    return const AnalyticsConfig(
      debug: true,
      batchSize: 5, // Flush more often in dev
      flushInterval: Duration(seconds: 10),
      environment: AnalyticsEnvironment.development,
    );
  }
}
