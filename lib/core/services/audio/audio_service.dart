import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'sound_definition.dart';
import 'audio_config.dart';
import '../../../game/settings/vibration_strength.dart';
import '../service_locator.dart';

abstract class AudioService {
  Future<void> initialize(AudioConfig config);
  Future<void> playSfx(SoundDefinition sound);
  Future<void> playMusic(String assetPath, {bool crossfade = true});
  Future<void> stopMusic();
  Future<void> pauseMusic();
  Future<void> resumeMusic();
  Future<void> setMusicVolume(double volume);
  Future<void> setSfxVolume(double volume);
  Future<void> preload(List<String> assetPaths);
  Future<void> release();

  // Haptics
  void playHapticLight() {
    final settings = ServiceLocator.instance.settingsManager.state;
    if (!settings.hapticsEnabled || settings.vibrationStrength == VibrationStrength.off) return;
    HapticFeedback.lightImpact();
  }

  void playHapticMedium() {
    final settings = ServiceLocator.instance.settingsManager.state;
    if (!settings.hapticsEnabled || settings.vibrationStrength == VibrationStrength.off) return;
    if (settings.vibrationStrength == VibrationStrength.light) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void playHapticHeavy() {
    final settings = ServiceLocator.instance.settingsManager.state;
    if (!settings.hapticsEnabled || settings.vibrationStrength == VibrationStrength.off) return;
    if (settings.vibrationStrength == VibrationStrength.light) {
      HapticFeedback.lightImpact();
    } else if (settings.vibrationStrength == VibrationStrength.medium) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }
}

/// A mock implementation that safely logs playback intents to the console.
/// Can be replaced with an actual audio engine implementation (like audioplayers) later.
class MockAudioService extends AudioService {
  String? _currentMusic;

  @override
  Future<void> initialize(AudioConfig config) async {
    if (kDebugMode) print('🔊 AudioService Initialized with cooldown ${config.defaultCooldown.inMilliseconds}ms');
  }

  @override
  Future<void> playSfx(SoundDefinition sound) async {
    if (kDebugMode) {
      print('🔊 SFX: ${sound.id} [vol: ${sound.volume.toStringAsFixed(2)}, pitch: ${sound.pitch.toStringAsFixed(2)}]');
    }
  }

  @override
  Future<void> playMusic(String assetPath, {bool crossfade = true}) async {
    if (_currentMusic == assetPath) return;
    _currentMusic = assetPath;
    if (kDebugMode) print('🎵 MUSIC START: $assetPath (crossfade: $crossfade)');
  }

  @override
  Future<void> stopMusic() async {
    _currentMusic = null;
    if (kDebugMode) print('🎵 MUSIC STOP');
  }

  @override
  Future<void> pauseMusic() async {
    if (kDebugMode) print('🎵 MUSIC PAUSE');
  }

  @override
  Future<void> resumeMusic() async {
    if (kDebugMode) print('🎵 MUSIC RESUME');
  }

  @override
  Future<void> setMusicVolume(double volume) async {
    if (kDebugMode) print('🎵 MUSIC VOL: ${volume.toStringAsFixed(2)}');
  }

  @override
  Future<void> setSfxVolume(double volume) async {
    if (kDebugMode) print('🔊 SFX VOL: ${volume.toStringAsFixed(2)}');
  }

  @override
  Future<void> preload(List<String> assetPaths) async {
    if (kDebugMode) print('🔊 PRELOAD: ${assetPaths.length} assets');
  }

  @override
  Future<void> release() async {
    if (kDebugMode) print('🔊 RELEASE RESOURCES');
  }
}
