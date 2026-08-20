enum VibrationStrength {
  off,
  light,
  medium,
  strong,
}

extension VibrationStrengthExtension on VibrationStrength {
  String get displayName {
    switch (this) {
      case VibrationStrength.off:
        return 'Off';
      case VibrationStrength.light:
        return 'Light';
      case VibrationStrength.medium:
        return 'Medium';
      case VibrationStrength.strong:
        return 'Strong';
    }
  }
}
