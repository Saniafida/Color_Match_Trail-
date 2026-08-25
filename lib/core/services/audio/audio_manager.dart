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

  // ─────────────────────────────────────────────
  // BGM CONVENIENCE METHODS
  // ─────────────────────────────────────────────

  void playHomeBgm() => playMusic('assets/sounds/music/bgm_home.wav');
  void playGameplayBgm() => playMusic('assets/sounds/music/bgm_gameplay.wav');
  void playMiniGamesBgm() => playMusic('assets/sounds/music/bgm_minigames.wav');

  // ─────────────────────────────────────────────
  // GAMEPLAY CONVENIENCE METHODS
  // ─────────────────────────────────────────────

  void playTileTap() {
    playSfx(const SoundDefinition(
      id: 'tile_tap',
      assetPath: 'assets/sounds/blocks/tile_tap.wav',
      type: AudioType.gameplay,
      volume: 0.6,
      priority: AudioPriority.low,
    ));
  }

  void playTrailDrag() {
    playSfx(const SoundDefinition(
      id: 'trail_drag',
      assetPath: 'assets/sounds/gameplay/trail_drag.wav',
      type: AudioType.gameplay,
      volume: 0.65,
      priority: AudioPriority.low,
    ));
  }

  void playMatch(int blocksCount) {
    double pitch = 1.0 + ((blocksCount - 3) * 0.05).clamp(0.0, 0.5);
    double volume = 0.8 + ((blocksCount - 3) * 0.1).clamp(0.0, 0.2);

    playSfx(SoundDefinition(
      id: 'match',
      assetPath: 'assets/sounds/blocks/match.wav',
      type: AudioType.gameplay,
      pitch: pitch,
      volume: volume,
    ));
  }

  void playBlast({bool isLarge = false}) {
    playSfx(SoundDefinition(
      id: isLarge ? 'blast_large' : 'blast',
      assetPath: isLarge
          ? 'assets/sounds/blast/blast_large.wav'
          : 'assets/sounds/blast/blast.wav',
      type: AudioType.blast,
      volume: isLarge ? 1.0 : 0.75,
      priority: isLarge ? AudioPriority.high : AudioPriority.normal,
    ));
  }

  void playCombo(int comboLevel) {
    double pitch = 1.0 + (comboLevel * 0.1).clamp(0.0, 1.0);
    playSfx(SoundDefinition(
      id: 'combo_$comboLevel',
      assetPath: 'assets/sounds/combo/combo.wav',
      type: AudioType.combo,
      pitch: pitch,
      priority: AudioPriority.high,
    ));
  }

  void playTileDrop() {
    playSfx(const SoundDefinition(
      id: 'tile_drop',
      assetPath: 'assets/sounds/blocks/tile_drop.wav',
      type: AudioType.gameplay,
      volume: 0.65,
      priority: AudioPriority.low,
    ));
  }

  void playGoalComplete() {
    playSfx(const SoundDefinition(
      id: 'goal_complete',
      assetPath: 'assets/sounds/ui/goal_complete.wav',
      type: AudioType.event,
      volume: 0.85,
      priority: AudioPriority.high,
    ));
  }

  void playStarEarn() {
    playSfx(const SoundDefinition(
      id: 'star_earn',
      assetPath: 'assets/sounds/events/star_earn.wav',
      type: AudioType.event,
      volume: 0.85,
      priority: AudioPriority.high,
    ));
  }

  void playLevelComplete() {
    playSfx(const SoundDefinition(
      id: 'level_complete',
      assetPath: 'assets/sounds/events/success.wav',
      type: AudioType.event,
      priority: AudioPriority.critical,
    ));
  }

  void playLevelFail() {
    playSfx(const SoundDefinition(
      id: 'level_fail',
      assetPath: 'assets/sounds/events/fail.wav',
      type: AudioType.event,
      priority: AudioPriority.critical,
    ));
  }

  // ─────────────────────────────────────────────
  // BOOSTERS CONVENIENCE METHODS
  // ─────────────────────────────────────────────

  void playHammer() {
    playSfx(const SoundDefinition(
      id: 'booster_hammer',
      assetPath: 'assets/sounds/boosters/booster_hammer.wav',
      type: AudioType.blast,
      volume: 0.9,
      priority: AudioPriority.high,
    ));
  }

  void playBomb() {
    playSfx(const SoundDefinition(
      id: 'booster_bomb',
      assetPath: 'assets/sounds/boosters/booster_bomb.wav',
      type: AudioType.blast,
      volume: 0.95,
      priority: AudioPriority.high,
    ));
  }

  void playColorBomb() {
    playSfx(const SoundDefinition(
      id: 'booster_color_bomb',
      assetPath: 'assets/sounds/boosters/booster_color_bomb.wav',
      type: AudioType.blast,
      volume: 0.9,
      priority: AudioPriority.high,
    ));
  }

  void playShuffle() {
    playSfx(const SoundDefinition(
      id: 'booster_shuffle',
      assetPath: 'assets/sounds/boosters/booster_shuffle.wav',
      type: AudioType.gameplay,
      volume: 0.8,
      priority: AudioPriority.normal,
    ));
  }

  void playExtraMoves() {
    playSfx(const SoundDefinition(
      id: 'booster_extra_moves',
      assetPath: 'assets/sounds/boosters/booster_extra_moves.wav',
      type: AudioType.event,
      volume: 0.85,
      priority: AudioPriority.high,
    ));
  }

  // ─────────────────────────────────────────────
  // MINI-GAMES CONVENIENCE METHODS
  // ─────────────────────────────────────────────

  void playSwapSlide() {
    playSfx(const SoundDefinition(
      id: 'swap_slide',
      assetPath: 'assets/sounds/minigames/swap_slide.wav',
      type: AudioType.gameplay,
      volume: 0.7,
      priority: AudioPriority.low,
    ));
  }

  void playSwapInvalid() {
    playSfx(const SoundDefinition(
      id: 'swap_invalid',
      assetPath: 'assets/sounds/minigames/swap_invalid.wav',
      type: AudioType.gameplay,
      volume: 0.75,
      priority: AudioPriority.normal,
    ));
  }

  void playLineBlast() {
    playSfx(const SoundDefinition(
      id: 'line_blast',
      assetPath: 'assets/sounds/minigames/line_blast.wav',
      type: AudioType.blast,
      volume: 0.9,
      priority: AudioPriority.high,
    ));
  }

  void playDropPodMove() {
    playSfx(const SoundDefinition(
      id: 'drop_slide_pod',
      assetPath: 'assets/sounds/minigames/drop_slide_pod.wav',
      type: AudioType.gameplay,
      volume: 0.5,
      priority: AudioPriority.low,
    ));
  }

  void playDropLanding() {
    playSfx(const SoundDefinition(
      id: 'drop_hard_landing',
      assetPath: 'assets/sounds/minigames/drop_hard_landing.wav',
      type: AudioType.gameplay,
      volume: 0.8,
      priority: AudioPriority.normal,
    ));
  }

  void playDangerAlert() {
    playSfx(const SoundDefinition(
      id: 'drop_danger_alert',
      assetPath: 'assets/sounds/minigames/drop_danger_alert.wav',
      type: AudioType.event,
      volume: 0.7,
      priority: AudioPriority.high,
    ));
  }

  void playStackPlace() {
    playSfx(const SoundDefinition(
      id: 'stack_place',
      assetPath: 'assets/sounds/minigames/stack_piece_place.wav',
      type: AudioType.gameplay,
      volume: 0.75,
      priority: AudioPriority.normal,
    ));
  }

  void playStackClearLine() {
    playSfx(const SoundDefinition(
      id: 'stack_line_clear',
      assetPath: 'assets/sounds/minigames/stack_line_clear.wav',
      type: AudioType.blast,
      volume: 0.9,
      priority: AudioPriority.high,
    ));
  }

  void playTubePop() {
    playSfx(const SoundDefinition(
      id: 'tube_pop',
      assetPath: 'assets/sounds/minigames/tube_cork_open.wav',
      type: AudioType.gameplay,
      volume: 0.8,
      priority: AudioPriority.normal,
    ));
  }

  void playLiquidPour() {
    playSfx(const SoundDefinition(
      id: 'liquid_pour',
      assetPath: 'assets/sounds/minigames/liquid_pour.wav',
      type: AudioType.gameplay,
      volume: 0.7,
      priority: AudioPriority.normal,
    ));
  }

  void playTubeComplete() {
    playSfx(const SoundDefinition(
      id: 'tube_complete',
      assetPath: 'assets/sounds/minigames/tube_done_sparkle.wav',
      type: AudioType.event,
      volume: 0.85,
      priority: AudioPriority.high,
    ));
  }

  // ─────────────────────────────────────────────
  // UI & ECONOMY CONVENIENCE METHODS
  // ─────────────────────────────────────────────

  void playButtonClick() {
    playSfx(const SoundDefinition(
      id: 'btn_click',
      assetPath: 'assets/sounds/ui/btn_click.wav',
      type: AudioType.ui,
      volume: 0.6,
      priority: AudioPriority.low,
    ));
  }

  void playPopupOpen() {
    playSfx(const SoundDefinition(
      id: 'popup_open',
      assetPath: 'assets/sounds/ui/popup_open.wav',
      type: AudioType.ui,
      volume: 0.65,
      priority: AudioPriority.low,
    ));
  }

  void playPopupClose() {
    playSfx(const SoundDefinition(
      id: 'popup_close',
      assetPath: 'assets/sounds/ui/popup_close.wav',
      type: AudioType.ui,
      volume: 0.6,
      priority: AudioPriority.low,
    ));
  }

  void playCoinCollect() {
    playSfx(const SoundDefinition(
      id: 'coin_collect',
      assetPath: 'assets/sounds/ui/coin_collect.wav',
      type: AudioType.ui,
      volume: 0.8,
      priority: AudioPriority.normal,
    ));
  }

  void playGemCollect() {
    playSfx(const SoundDefinition(
      id: 'gem_collect',
      assetPath: 'assets/sounds/ui/gem_collect.wav',
      type: AudioType.ui,
      volume: 0.8,
      priority: AudioPriority.normal,
    ));
  }

  void playChestOpen() {
    playSfx(const SoundDefinition(
      id: 'chest_open',
      assetPath: 'assets/sounds/ui/chest_open.wav',
      type: AudioType.event,
      volume: 0.9,
      priority: AudioPriority.high,
    ));
  }

  void playWheelSpin() {
    playSfx(const SoundDefinition(
      id: 'wheel_spin',
      assetPath: 'assets/sounds/ui/wheel_spin.wav',
      type: AudioType.ui,
      volume: 0.6,
      priority: AudioPriority.low,
    ));
  }

  void playWheelWin() {
    playSfx(const SoundDefinition(
      id: 'wheel_win',
      assetPath: 'assets/sounds/ui/wheel_win.wav',
      type: AudioType.event,
      volume: 0.9,
      priority: AudioPriority.critical,
    ));
  }

  void playShopPurchase() {
    playSfx(const SoundDefinition(
      id: 'shop_buy',
      assetPath: 'assets/sounds/ui/shop_buy.wav',
      type: AudioType.ui,
      volume: 0.8,
      priority: AudioPriority.high,
    ));
  }

  void playAchievementUnlock() {
    playSfx(const SoundDefinition(
      id: 'achievement_unlock',
      assetPath: 'assets/sounds/ui/achievement_unlock.wav',
      type: AudioType.event,
      volume: 0.85,
      priority: AudioPriority.high,
    ));
  }

  void playSwitchToggle() {
    playSfx(const SoundDefinition(
      id: 'switch_toggle',
      assetPath: 'assets/sounds/ui/switch_toggle.wav',
      type: AudioType.ui,
      volume: 0.55,
      priority: AudioPriority.low,
    ));
  }

  void playUI(String action) {
    playSfx(SoundDefinition(
      id: 'ui_$action',
      assetPath: 'assets/sounds/ui/btn_click.wav',
      type: AudioType.ui,
      volume: 0.5,
      priority: AudioPriority.low,
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
