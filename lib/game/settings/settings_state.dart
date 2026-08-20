import 'vibration_strength.dart';

class SettingsState {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final bool effectsEnabled;
  final bool notificationsEnabled;
  final bool reducedEffects;
  final VibrationStrength vibrationStrength;
  final String language;

  const SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.effectsEnabled = true,
    this.notificationsEnabled = true,
    this.reducedEffects = false,
    this.vibrationStrength = VibrationStrength.medium,
    this.language = 'system',
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    bool? effectsEnabled,
    bool? notificationsEnabled,
    bool? reducedEffects,
    VibrationStrength? vibrationStrength,
    String? language,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      effectsEnabled: effectsEnabled ?? this.effectsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reducedEffects: reducedEffects ?? this.reducedEffects,
      vibrationStrength: vibrationStrength ?? this.vibrationStrength,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'hapticsEnabled': hapticsEnabled,
      'effectsEnabled': effectsEnabled,
      'notificationsEnabled': notificationsEnabled,
      'reducedEffects': reducedEffects,
      'vibrationStrength': vibrationStrength.name,
      'language': language,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      soundEnabled: json['soundEnabled'] ?? true,
      musicEnabled: json['musicEnabled'] ?? true,
      hapticsEnabled: json['hapticsEnabled'] ?? true,
      effectsEnabled: json['effectsEnabled'] ?? true,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      reducedEffects: json['reducedEffects'] ?? false,
      vibrationStrength: VibrationStrength.values.firstWhere(
        (e) => e.name == json['vibrationStrength'],
        orElse: () => VibrationStrength.medium,
      ),
      language: json['language'] ?? 'system',
    );
  }
}
