import 'dart:math';
import 'player_statistics.dart';

/// Validates profile data and ensures statistics do not contain impossible values.
class ProfileValidator {
  
  static const int _maxNameLength = 16;
  static const int _minNameLength = 3;

  /// Returns a valid, safe display name.
  static String sanitizeDisplayName(String input, String fallback) {
    String clean = input.trim().replaceAll(RegExp(r'\s+'), ' '); // Collapse spaces
    clean = clean.replaceAll(RegExp(r'[^\w\s]'), ''); // Remove special chars

    if (clean.length < _minNameLength) {
      return fallback;
    }
    
    if (clean.length > _maxNameLength) {
      clean = clean.substring(0, _maxNameLength);
    }
    
    // Simple reserved word check
    if (clean.toLowerCase() == 'admin' || clean.toLowerCase() == 'system') {
      return fallback;
    }

    return clean;
  }

  /// Ensures statistics only ever grow positively and impossible states are corrected.
  static PlayerStatistics validateStatistics(PlayerStatistics current) {
    int safePlayed = max(0, current.gamesPlayed);
    int safeWon = max(0, current.gamesWon);
    
    // Impossible state: Can't win more than you play
    if (safeWon > safePlayed) {
      safeWon = safePlayed;
    }

    return PlayerStatistics(
      gamesPlayed: safePlayed,
      gamesWon: safeWon,
      totalStars: max(0, current.totalStars),
      totalScore: max(0, current.totalScore),
      highestCombo: max(0, current.highestCombo),
      boostersUsed: max(0, current.boostersUsed),
    );
  }
}
