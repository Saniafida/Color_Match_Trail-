import 'package:flutter/foundation.dart';
import '../../game/settings/settings_manager.dart';
import 'performance_config.dart';
import 'performance_logger.dart';
import 'performance_mode.dart';

class PerformanceManager extends ChangeNotifier {
  final SettingsManager settingsManager;
  final PerformanceLogger logger = PerformanceLogger();

  PerformanceConfig _config = PerformanceConfig.forMode(PerformanceMode.medium);

  PerformanceManager({required this.settingsManager}) {
    settingsManager.addListener(_onSettingsChanged);
  }

  PerformanceConfig get config => _config;

  void initialize() {
    _refreshConfig();
  }

  void _onSettingsChanged() {
    _refreshConfig();
  }

  void _refreshConfig() {
    final reducedEffects = settingsManager.state.reducedEffects;

    if (reducedEffects) {
      _config = PerformanceConfig.reduced();
      if (kDebugMode) logger.logEvent('PerformanceConfig set to REDUCED (from SettingsManager)');
    } else {
      // Future: detect device class here for true auto-detection.
      // For now, default to medium-safe behavior.
      _config = PerformanceConfig.forMode(PerformanceMode.medium);
      if (kDebugMode) logger.logEvent('PerformanceConfig set to MEDIUM');
    }

    notifyListeners();
  }

  /// Manually override the performance mode (e.g., during testing or by user).
  void setMode(PerformanceMode mode) {
    _config = PerformanceConfig.forMode(mode);
    logger.logEvent('PerformanceMode manually set to ${mode.name}');
    notifyListeners();
  }

  @override
  void dispose() {
    settingsManager.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
