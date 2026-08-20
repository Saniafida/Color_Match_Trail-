import 'performance_mode.dart';

class ParticleConfig {
  final int maxSmallBlastParticles;
  final int maxLargeBlastParticles;
  final int maxMegaBlastParticles;
  final bool glowEnabled;
  final bool shadowsEnabled;
  final bool screenShakeEnabled;

  const ParticleConfig({
    required this.maxSmallBlastParticles,
    required this.maxLargeBlastParticles,
    required this.maxMegaBlastParticles,
    required this.glowEnabled,
    required this.shadowsEnabled,
    required this.screenShakeEnabled,
  });

  factory ParticleConfig.forMode(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.low:
        return const ParticleConfig(
          maxSmallBlastParticles: 4,
          maxLargeBlastParticles: 6,
          maxMegaBlastParticles: 8,
          glowEnabled: false,
          shadowsEnabled: false,
          screenShakeEnabled: false,
        );
      case PerformanceMode.medium:
        return const ParticleConfig(
          maxSmallBlastParticles: 6,
          maxLargeBlastParticles: 10,
          maxMegaBlastParticles: 14,
          glowEnabled: true,
          shadowsEnabled: true,
          screenShakeEnabled: true,
        );
      case PerformanceMode.high:
      case PerformanceMode.auto:
        return const ParticleConfig(
          maxSmallBlastParticles: 8,
          maxLargeBlastParticles: 12,
          maxMegaBlastParticles: 20,
          glowEnabled: true,
          shadowsEnabled: true,
          screenShakeEnabled: true,
        );
    }
  }
}
