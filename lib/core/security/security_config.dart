/// Defines the environment for security enforcement.
enum SecurityEnvironment {
  /// Development mode: Debug tools, verbose logging enabled.
  development,
  
  /// Staging mode: Close to production but with diagnostic overrides.
  staging,
  
  /// Production mode: Strict enforcement, obfuscation-ready, debug tools disabled.
  production,
}

/// Configuration for the Security System.
class SecurityConfig {
  final SecurityEnvironment environment;
  
  /// Secret key for HMAC signing local saves (Keep out of source in real apps).
  /// For this client-side mockup, we use a constant.
  final String localSaveSecretKey;

  const SecurityConfig({
    this.environment = SecurityEnvironment.development,
    this.localSaveSecretKey = 'CLIENT_SIDE_ONLY_DEFAULT_SECRET',
  });

  bool get isProduction => environment == SecurityEnvironment.production;
  bool get allowDebugTools => !isProduction;
}
