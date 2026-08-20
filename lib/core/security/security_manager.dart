import 'package:flutter/foundation.dart';

import 'security_config.dart';
import 'security_event_logger.dart';
import 'game_time_service.dart';
import 'save_integrity_manager.dart';
import 'transaction_validator.dart';
import 'reward_validator.dart';
import 'progression_validator.dart';
import 'inventory_validator.dart';
import 'currency_validator.dart';
import 'score_validation_service.dart';
import '../../core/data/game_data_manager.dart';
import '../../core/storage/game_save_manager.dart';
import '../services/analytics/analytics_manager.dart';

/// Central coordinator for the Security System.
class SecurityManager {
  final SecurityConfig config;
  final GameDataManager gameDataManager;
  final GameSaveManager saveManager;
  final AnalyticsManager analyticsManager;

  late final SecurityEventLogger eventLogger;
  late final GameTimeService timeService;
  late final SaveIntegrityManager integrityManager;
  
  late final TransactionValidator transactionValidator;
  late final RewardValidator rewardValidator;
  late final ProgressionValidator progressionValidator;
  late final InventoryValidator inventoryValidator;
  late final CurrencyValidator currencyValidator;
  late final ScoreValidationService scoreValidator;

  SecurityManager({
    required this.config,
    required this.gameDataManager,
    required this.saveManager,
    required this.analyticsManager,
  }) {
    eventLogger = SecurityEventLogger(analyticsManager);
    timeService = GameTimeService(eventLogger);
    integrityManager = SaveIntegrityManager(config);
    
    transactionValidator = TransactionValidator(eventLogger);
    rewardValidator = RewardValidator(eventLogger);
    progressionValidator = ProgressionValidator(eventLogger, gameDataManager);
    inventoryValidator = InventoryValidator(eventLogger);
    currencyValidator = CurrencyValidator(eventLogger);
    scoreValidator = ScoreValidationService(eventLogger);
  }

  void initialize() {
    if (kDebugMode) {
      print('[SecurityManager] Initializing in ${config.environment.name} mode.');
    }
    
    timeService.initialize();
  }

  void dispose() {
    timeService.dispose();
  }
}
