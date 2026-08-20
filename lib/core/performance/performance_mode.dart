enum PerformanceMode {
  /// Reduced effects, lower particle count. Suitable for low-end devices.
  low,

  /// Balanced effects. Default for most devices.
  medium,

  /// Full effects enabled. For high-end devices.
  high,

  /// Automatically determined based on device capability and settings.
  auto,
}
