import 'particle_config.dart';
import 'performance_mode.dart';

class PerformanceConfig {
  final PerformanceMode mode;
  final ParticleConfig particles;
  final bool animationsEnabled;

  const PerformanceConfig({
    required this.mode,
    required this.particles,
    this.animationsEnabled = true,
  });

  factory PerformanceConfig.forMode(PerformanceMode mode) {
    return PerformanceConfig(
      mode: mode,
      particles: ParticleConfig.forMode(mode),
      animationsEnabled: mode != PerformanceMode.low,
    );
  }

  factory PerformanceConfig.reduced() {
    // Used when SettingsManager.reducedEffects = true
    return PerformanceConfig(
      mode: PerformanceMode.low,
      particles: ParticleConfig.forMode(PerformanceMode.low),
      animationsEnabled: true, // Animations still play, just fewer particles/effects
    );
  }

  bool get glowEnabled => particles.glowEnabled;
  bool get shadowsEnabled => particles.shadowsEnabled;
  bool get screenShakeEnabled => particles.screenShakeEnabled;
}
