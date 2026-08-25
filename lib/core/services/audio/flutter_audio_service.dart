import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'sound_definition.dart';
import 'audio_config.dart';
import 'audio_service.dart';

/// Real, high-performance implementation of AudioService using audioplayers.
/// Supports dedicated looping BGM and a low-latency SFX player pool.
class FlutterAudioService extends AudioService {
  AudioPlayer? _musicPlayer;
  final List<AudioPlayer> _sfxPool = [];
  int _nextSfxIndex = 0;
  static const int _sfxPoolSize = 6;

  double _musicVolume = 0.5;
  double _sfxVolume = 1.0;
  String? _currentMusicAsset;
  bool _isInitialized = false;

  @override
  Future<void> initialize(AudioConfig config) async {
    if (_isInitialized) return;

    try {
      AudioCache.instance.prefix = '';

      _musicPlayer = AudioPlayer(playerId: 'bgm_player');
      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer?.setVolume(_musicVolume);

      for (int i = 0; i < _sfxPoolSize; i++) {
        final player = AudioPlayer(playerId: 'sfx_player_$i');
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_sfxVolume);
        _sfxPool.add(player);
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('🔊 FlutterAudioService initialized with $_sfxPoolSize SFX channels.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FlutterAudioService initialize error: $e');
      }
      _isInitialized = true; // allow fallback play on demand
    }
  }

  String _normalizeAssetPath(String path) {
    if (path.startsWith('assets/')) return path;
    return 'assets/$path';
  }

  @override
  Future<void> playSfx(SoundDefinition sound) async {
    try {
      final normPath = _normalizeAssetPath(sound.assetPath);
      final finalVolume = (_sfxVolume * sound.volume).clamp(0.0, 1.0);

      AudioPlayer player;
      if (_sfxPool.isNotEmpty) {
        player = _sfxPool[_nextSfxIndex];
        _nextSfxIndex = (_nextSfxIndex + 1) % _sfxPool.length;
      } else {
        player = AudioPlayer();
      }

      await player.setVolume(finalVolume);
      if (sound.pitch != 1.0) {
        try {
          await player.setPlaybackRate(sound.pitch.clamp(0.5, 2.0));
        } catch (_) {}
      }

      await player.stop();
      await player.play(
        AssetSource(normPath),
        mode: PlayerMode.lowLatency,
      );

      if (kDebugMode) {
        print('🔊 SFX Play: $normPath (vol: ${finalVolume.toStringAsFixed(2)})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ SFX play error for ${sound.assetPath}: $e');
      }
    }
  }

  @override
  Future<void> playMusic(String assetPath, {bool crossfade = true}) async {
    _currentMusicAsset = assetPath;
    try {
      _musicPlayer ??= AudioPlayer(playerId: 'bgm_player');
      final normPath = _normalizeAssetPath(assetPath);

      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer?.setVolume(_musicVolume);
      await _musicPlayer?.stop();
      await _musicPlayer?.play(
        AssetSource(normPath),
        mode: PlayerMode.mediaPlayer,
      );

      if (kDebugMode) {
        print('🎵 BGM Play: $normPath (vol: ${_musicVolume.toStringAsFixed(2)})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ BGM play error for $assetPath: $e');
      }
    }
  }

  @override
  Future<void> stopMusic() async {
    _currentMusicAsset = null;
    try {
      await _musicPlayer?.stop();
    } catch (_) {}
  }

  @override
  Future<void> pauseMusic() async {
    try {
      await _musicPlayer?.pause();
    } catch (_) {}
  }

  @override
  Future<void> resumeMusic() async {
    if (_currentMusicAsset != null) {
      try {
        await _musicPlayer?.resume();
      } catch (_) {}
    }
  }

  @override
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    try {
      await _musicPlayer?.setVolume(_musicVolume);
    } catch (_) {}
  }

  @override
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    for (final player in _sfxPool) {
      try {
        await player.setVolume(_sfxVolume);
      } catch (_) {}
    }
  }

  @override
  Future<void> preload(List<String> assetPaths) async {}

  @override
  Future<void> release() async {
    try {
      await _musicPlayer?.dispose();
      for (final player in _sfxPool) {
        await player.dispose();
      }
      _sfxPool.clear();
      _isInitialized = false;
    } catch (_) {}
  }
}
