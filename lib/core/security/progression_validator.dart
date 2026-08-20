import 'dart:math';
import 'security_event_logger.dart';
import '../../core/data/game_data_manager.dart';

/// Validates player progression ensuring they cannot skip levels or hack unlocks.
class ProgressionValidator {
  final SecurityEventLogger _logger;
  final GameDataManager _gameDataManager;

  ProgressionValidator(this._logger, this._gameDataManager);

  /// Validates and corrects campaign progress safely.
  Map<String, dynamic> validateCampaignProgress(Map<String, dynamic> progress) {
    final safeProgress = Map<String, dynamic>.from(progress);

    // Validate highest unlocked level
    int highest = (progress['highestUnlockedLevel'] as num?)?.toInt() ?? 1;
    if (highest < 1) {
      _logger.logProgressionAnomaly('highestUnlockedLevel < 1');
      highest = 1;
    }

    // Check against total available levels in the game data
    final totalLevels = _gameDataManager.getAllLevels().length;
    if (totalLevels > 0 && highest > totalLevels) {
      _logger.logProgressionAnomaly('highestUnlockedLevel > total available levels');
      highest = totalLevels;
    }

    safeProgress['highestUnlockedLevel'] = highest;

    // Validate completed levels list
    final completed = (progress['completedLevels'] as List<dynamic>?)?.cast<int>() ?? <int>[];
    final safeCompleted = <int>[];
    
    for (int lvl in completed) {
      if (lvl > 0 && (totalLevels == 0 || lvl <= totalLevels)) {
        safeCompleted.add(lvl);
      } else {
        _logger.logProgressionAnomaly('Invalid level ID in completedLevels: $lvl');
      }
    }
    
    // Ensure highest unlocked makes sense based on completed levels
    // Normally, if you've completed up to N, highest unlocked should be N+1
    if (safeCompleted.isNotEmpty) {
      final maxCompleted = safeCompleted.reduce(max);
      if (highest > maxCompleted + 1) {
        _logger.logProgressionAnomaly('highestUnlockedLevel too far ahead of completedLevels');
        // We do NOT strictly revert highest to maxCompleted+1 because there might be
        // legitimate skips (e.g. ad to skip level). But we log it as an anomaly.
      }
    }

    safeProgress['completedLevels'] = safeCompleted;
    return safeProgress;
  }
}
