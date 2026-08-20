import 'package:flutter/foundation.dart';
import 'settings_state.dart';
import 'settings_storage.dart';
import 'vibration_strength.dart';

class SettingsManager extends ChangeNotifier {
  final SettingsStorage storage;
  
  SettingsState _state = const SettingsState();
  SettingsState get state => _state;

  SettingsManager({required this.storage});

  Future<void> initialize() async {
    final loaded = await storage.loadSettings();
    if (loaded != null) {
      _state = loaded;
    } else {
      _state = const SettingsState();
      await storage.saveSettings(_state);
    }
    notifyListeners();
  }

  Future<void> updateSettings(SettingsState newState) async {
    _state = newState;
    await storage.saveSettings(_state);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _state = const SettingsState();
    await storage.saveSettings(_state);
    notifyListeners();
  }

  // Quick toggles
  Future<void> toggleSound() => updateSettings(_state.copyWith(soundEnabled: !_state.soundEnabled));
  Future<void> toggleMusic() => updateSettings(_state.copyWith(musicEnabled: !_state.musicEnabled));
  Future<void> toggleHaptics() => updateSettings(_state.copyWith(hapticsEnabled: !_state.hapticsEnabled));
  Future<void> toggleEffects() => updateSettings(_state.copyWith(effectsEnabled: !_state.effectsEnabled));
  Future<void> toggleNotifications() => updateSettings(_state.copyWith(notificationsEnabled: !_state.notificationsEnabled));
  Future<void> toggleReducedEffects() => updateSettings(_state.copyWith(reducedEffects: !_state.reducedEffects));
  Future<void> setVibrationStrength(VibrationStrength strength) => updateSettings(_state.copyWith(vibrationStrength: strength));
  Future<void> setLanguage(String language) => updateSettings(_state.copyWith(language: language));
}
