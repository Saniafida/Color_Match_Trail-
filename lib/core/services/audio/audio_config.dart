class AudioConfig {
  final double defaultMusicVolume;
  final double defaultSfxVolume;
  final int maxSimultaneousSounds;
  final Duration fadeDuration;
  final Duration defaultCooldown;

  const AudioConfig({
    this.defaultMusicVolume = 0.5,
    this.defaultSfxVolume = 1.0,
    this.maxSimultaneousSounds = 10,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.defaultCooldown = const Duration(milliseconds: 50),
  });

  factory AudioConfig.lowPerformance() {
    return const AudioConfig(
      defaultMusicVolume: 0.5,
      defaultSfxVolume: 1.0,
      maxSimultaneousSounds: 5,
      fadeDuration: Duration(milliseconds: 0),
      defaultCooldown: Duration(milliseconds: 100),
    );
  }
}
