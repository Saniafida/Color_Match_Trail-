import 'package:flutter/foundation.dart';
import '../../../game/settings/settings_manager.dart';
import '../../performance/performance_manager.dart';
import '../../performance/performance_mode.dart';
import '../error_reporting/error_reporting_manager.dart';
import '../error_reporting/error_category.dart';
import 'audio_service.dart';
import 'audio_config.dart';
import 'sound_definition.dart';
import 'audio_priority.dart';
import 'audio_type.dart';

class AudioManager extends ChangeNotifier {
  final AudioService _service;
  final SettingsManager _settingsManager;
  final PerformanceManager _performanceManager;
  final ErrorReportingManager _errorReportingManager;

  AudioConfig _config = const AudioConfig();
  final Map<String, DateTime> _lastPlayed = {};
  int _activeSoundsCount = 0;
  String? _currentMusicAsset;

  AudioManager({
    required AudioService service,
    required SettingsManager settingsManager,
    required PerformanceManager performanceManager,
    required ErrorReportingManager errorReportingManager,
  })  : _service = service,
        _settingsManager = settingsManager,
        _performanceManager = performanceManager,
        _errorReportingManager = errorReportingManager {
    _settingsManager.addListener(_onSettingsChanged);
    _performanceManager.addListener(_onPerformanceChanged);
  }

  Future<void> initialize() async {
    _updateConfig();
    try {
      await _service.initialize(_config);
      _applyVolumes();
    } catch (e, st) {
      _errorReportingManager.reportException(e, st, category: ErrorCategory.audio);
    }
  }

  void _onSettingsChanged() {
    _applyVolumes();
    if (!_settingsManager.state.musicEnabled) {
      _service.pauseMusic();
    } else if (_currentMusicAsset != null) {
      _service.resumeMusic();
    }
  }

  void _onPerformanceChanged() {
    _updateConfig();
  }

  void _updateConfig() {
    if (_performanceManager.config.mode == PerformanceMode.low) {
      _config = AudioConfig.lowPerformance();
    } else {
      _config = const AudioConfig();
    }
  }

  void _applyVolumes() {
    final state = _settingsManager.state;
    _service.setMusicVolume(state.musicEnabled ? _config.defaultMusicVolume : 0.0);
    _service.setSfxVolume(state.soundEnabled ? _config.defaultSfxVolume : 0.0);
  }

  Future<void> playSfx(SoundDefinition sound) async {
    if (!_settingsManager.state.soundEnabled) return;

    // Spam Protection / Throttling
    final now = DateTime.now();
    if (_lastPlayed.containsKey(sound.id)) {
      if (now.difference(_lastPlayed[sound.id]!) < _config.defaultCooldown) {
        return; // Throttled
      }
    }

    // Capacity Protection
    if (_activeSoundsCount >= _config.maxSimultaneousSounds && sound.priority.value < AudioPriority.high.value) {
      return; // Dropped low priority sound due to capacity
    }

    _lastPlayed[sound.id] = now;
    _activeSoundsCount++;

    try {
      await _service.playSfx(sound);
    } catch (e, st) {
      _errorReportingManager.reportException(e, st, category: ErrorCategory.audio);
    } finally {
      // Simulate sound duration roughly, or rely on actual engine callback later
      Future.delayed(const Duration(seconds: 1), () {
        if (_activeSoundsCount > 0) _activeSoundsCount--;
      });
    }
  }

  Future<void> playMusic(String assetPath, {bool crossfade = true}) async {
    _currentMusicAsset = assetPath;
    if (!_settingsManager.state.musicEnabled) return;

    try {
      await _service.playMusic(assetPath, crossfade: crossfade);
    } catch (e, st) {
      _errorReportingManager.reportException(e, st, category: ErrorCategory.audio);
    }
  }

  Future<void> pauseAll() async {
    try {
      await _service.pauseMusic();
    } catch (_) {}
  }

  Future<void> resumeAll() async {
    if (_settingsManager.state.musicEnabled && _currentMusicAsset != null) {
      try {
        await _service.resumeMusic();
      } catch (_) {}
    }
  }

  // --- Convenience Methods for Gameplay ---

  void playMatch(int blocksCount) {
    // Escalate pitch/volume based on match size
    double pitch = 1.0 + ((blocksCount - 3) * 0.05).clamp(0.0, 0.5);
    double volume = 0.8 + ((blocksCount - 3) * 0.1).clamp(0.0, 0.2);

    playSfx(SoundDefinition(
      id: 'match',
      assetPath: 'assets/sounds/blocks/match.mp3',
      type: AudioType.gameplay,
      pitch: pitch,
      volume: volume,
    ));
  }

  void playBlast({bool isLarge = false}) {
    playSfx(SoundDefinition(
      id: isLarge ? 'blast_large' : 'blast',
      assetPath: 'assets/sounds/blast/blast.mp3',
      type: AudioType.blast,
      volume: isLarge ? 1.0 : 0.7,
      priority: isLarge ? AudioPriority.high : AudioPriority.normal,
    ));
  }

  void playCombo(int comboLevel) {
    double pitch = 1.0 + (comboLevel * 0.1).clamp(0.0, 1.0);
    playSfx(SoundDefinition(
      id: 'combo_$comboLevel', // Allow distinct sounds per combo level to play simultaneously
      assetPath: 'assets/sounds/combo/combo.mp3',
      type: AudioType.combo,
      pitch: pitch,
      priority: AudioPriority.high,
    ));
  }

  void playUI(String action) {
    playSfx(SoundDefinition(
      id: 'ui_$action',
      assetPath: 'assets/sounds/ui/$action.mp3',
      type: AudioType.ui,
      volume: 0.5,
      priority: AudioPriority.low,
    ));
  }

  void playLevelComplete() {
    playSfx(const SoundDefinition(
      id: 'level_complete',
      assetPath: 'assets/sounds/events/success.mp3',
      type: AudioType.event,
      priority: AudioPriority.critical,
    ));
  }

  void playLevelFail() {
    playSfx(const SoundDefinition(
      id: 'level_fail',
      assetPath: 'assets/sounds/events/fail.mp3',
      type: AudioType.event,
      priority: AudioPriority.critical,
    ));
  }

  void playHapticLight() => _service.playHapticLight();
  void playHapticMedium() => _service.playHapticMedium();
  void playHapticHeavy() => _service.playHapticHeavy();

  @override
  void dispose() {
    _settingsManager.removeListener(_onSettingsChanged);
    _performanceManager.removeListener(_onPerformanceChanged);
    _service.release();
    super.dispose();
  }
}
