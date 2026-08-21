import '../storage/storage.dart';
import '../../game/levels/level_repository.dart';
import '../../game/progression/progression_manager.dart';
import '../../game/balance/game_balance_manager.dart';
import '../../game/balance/difficulty_manager.dart';
import 'audio/audio_service.dart';
import 'audio/audio_manager.dart';
import 'date_service.dart';
import '../../game/challenges/daily_challenge_storage.dart';
import '../../game/challenges/daily_challenge_generator.dart';
import '../../game/challenges/daily_challenge_manager.dart';
import '../../game/events/event_storage.dart';
import '../../game/events/event_manager.dart';
import '../../game/coins/coin_manager.dart';
import '../../game/inventory/inventory_manager.dart';
import '../../game/rewards/reward_claim_store.dart';
import '../../game/rewards/reward_manager.dart';
import '../../game/shop/shop_repository.dart';
import '../../game/shop/shop_manager.dart';
import '../../game/results/level_result_manager.dart';
import '../../game/settings/settings_storage.dart';
import '../../game/settings/settings_manager.dart';
import '../storage/game_save_manager.dart';
import '../storage/game_save_manager_storage.dart';

import '../../game/statistics/statistics_manager.dart';
import '../../game/achievements/achievement_storage.dart';
import '../../game/achievements/achievement_manager.dart';
import '../../game/achievements/milestone_manager.dart';
import '../../game/onboarding/onboarding_storage.dart';
import '../../game/onboarding/onboarding_manager.dart';
import '../../game/tutorial/tutorial_manager.dart';
import 'notifications/notification_manager.dart';
import 'notifications/notification_scheduler.dart';
import 'notifications/notification_service.dart';
import 'notifications/notification_storage.dart';
import 'monetization/ad_service.dart';
import 'monetization/ad_consent_manager.dart';
import 'monetization/ad_free_manager.dart';
import 'monetization/ad_frequency_controller.dart';
import 'monetization/monetization_manager.dart';
import 'analytics/analytics_service.dart';
import 'analytics/analytics_config.dart';
import 'analytics/analytics_manager.dart';
import '../localization/localization_manager.dart';
import '../performance/performance_manager.dart';
import 'error_reporting/error_reporting_manager.dart';
import '../../core/data/game_data_manager.dart';
import '../security/security_config.dart';
import '../security/save_backup_manager.dart';
import '../security/save_integrity_manager.dart';
import '../security/security_manager.dart';
import '../../game/profile/player_profile_manager.dart';

class ServiceLocator {
  static final ServiceLocator instance = ServiceLocator._internal();

  ServiceLocator._internal();

  late final GameStorage storage;
  late final LevelRepository levelRepository;
  late final ProgressionManager progressionManager;
  late final LevelResultManager levelResultManager;
  late final AudioManager audioManager;
  late final GameBalanceManager gameBalanceManager;
  late final DifficultyManager difficultyManager;

  late final DateService dateService;
  late final DailyChallengeStorage dailyChallengeStorage;
  late final DailyChallengeGenerator dailyChallengeGenerator;
  late final DailyChallengeManager dailyChallengeManager;
  
  late final EventStorage eventStorage;
  late final EventManager eventManager;

  late final CoinManager coinManager;
  late final InventoryManager inventoryManager;
  late final RewardClaimStore rewardClaimStore;
  late final RewardManager rewardManager;

  late final ShopRepository shopRepository;
  late final ShopManager shopManager;

  late final SettingsStorage settingsStorage;
  late final SettingsManager settingsManager;

  late final SaveBackupManager saveBackupManager;
  late final GameSaveManager gameSaveManager;

  late final StatisticsManager statisticsManager;
  late final AchievementStorage achievementStorage;
  late final AchievementManager achievementManager;
  late final MilestoneManager milestoneManager;

  late final OnboardingStorage onboardingStorage;
  late final OnboardingManager onboardingManager;
  late final TutorialManager tutorialManager;

  late final NotificationService notificationService;
  late final NotificationScheduler notificationScheduler;
  late final NotificationStorage notificationStorage;
  late final NotificationManager notificationManager;

  late final AdService adService;
  late final AdConsentManager adConsentManager;
  late final AdFreeManager adFreeManager;
  late final AdFrequencyController adFrequencyController;
  late final MonetizationManager monetizationManager;

  late final AnalyticsService analyticsService;
  late final AnalyticsManager analyticsManager;

  late final LocalizationManager localizationManager;
  late final PerformanceManager performanceManager;
  late final ErrorReportingManager errorReportingManager;
  late final GameDataManager gameDataManager;
  
  late final SecurityConfig securityConfig;
  late final SaveIntegrityManager saveIntegrityManager;
  late final SecurityManager securityManager;

  late final PlayerProfileManager playerProfileManager;

  Future<void> initialize() async {
    securityConfig = const SecurityConfig();
    saveIntegrityManager = SaveIntegrityManager(securityConfig);
    
    saveBackupManager = SaveBackupManager();
    gameSaveManager = GameSaveManager(
      backupManager: saveBackupManager,
      integrityManager: saveIntegrityManager,
    );
    await gameSaveManager.initialize();

    storage = GameSaveManagerStorage(saveManager: gameSaveManager);
    await storage.init();

    levelRepository = LevelRepository();
    // Load the bundled levels asynchronously
    await levelRepository.preloadAll();

    dateService = DateService();
    dailyChallengeStorage = DailyChallengeStorage(saveManager: gameSaveManager);
    dailyChallengeGenerator = DailyChallengeGenerator();
    
    dailyChallengeManager = DailyChallengeManager(
      dateService: dateService,
      challengeStorage: dailyChallengeStorage,
      gameStorage: storage,
      generator: dailyChallengeGenerator,
    );
    await dailyChallengeManager.initialize();

    eventStorage = EventStorage(saveManager: gameSaveManager);
    eventManager = EventManager(
      dateService: dateService,
      eventStorage: eventStorage,
      gameStorage: storage,
    );
    await eventManager.initialize();
    
    coinManager = CoinManager(storage: storage);
    await coinManager.initialize();

    inventoryManager = InventoryManager(storage: storage);
    await inventoryManager.initialize();

    rewardClaimStore = RewardClaimStore(saveManager: gameSaveManager);
    rewardManager = RewardManager(
      coinManager: coinManager,
      inventoryManager: inventoryManager,
      claimStore: rewardClaimStore,
    );

    shopRepository = ShopRepository();
    shopManager = ShopManager(
      repository: shopRepository,
      coinManager: coinManager,
      inventoryManager: inventoryManager,
    );
    await shopManager.initialize();

    settingsStorage = SettingsStorage(saveManager: gameSaveManager);
    settingsManager = SettingsManager(storage: settingsStorage);
    await settingsManager.initialize();

    localizationManager = LocalizationManager(settingsManager: settingsManager);
    await localizationManager.initialize();

    performanceManager = PerformanceManager(settingsManager: settingsManager);
    performanceManager.initialize();

    analyticsService = StubAnalyticsService();
    analyticsManager = AnalyticsManager(
      service: analyticsService,
      saveManager: gameSaveManager,
      config: AnalyticsConfig.development(), // Using dev config for now
    );
    await analyticsManager.initialize();

    errorReportingManager = ErrorReportingManager(analyticsManager: analyticsManager);
    await errorReportingManager.initialize();

    audioManager = AudioManager(
      service: MockAudioService(),
      settingsManager: settingsManager,
      performanceManager: performanceManager,
      errorReportingManager: errorReportingManager,
    );
    await audioManager.initialize();

    difficultyManager = const DifficultyManager();
    gameBalanceManager = GameBalanceManager();
    await gameBalanceManager.initialize();

    // Initialize GameDataManager after levels and error reporting are ready
    gameDataManager = GameDataManager(
      errorReportingManager: errorReportingManager,
    );
    await gameDataManager.initialize();

    progressionManager = ProgressionManager(
      saveManager: gameSaveManager,
      dataManager: gameDataManager,
      rewardManager: rewardManager,
    );
    progressionManager.initialize();

    levelResultManager = LevelResultManager(
      progressionManager: progressionManager,
      rewardManager: rewardManager,
    );

    statisticsManager = StatisticsManager(saveManager: gameSaveManager);
    statisticsManager.initialize();

    achievementStorage = AchievementStorage(saveManager: gameSaveManager);
    achievementManager = AchievementManager(
      storage: achievementStorage,
      rewardManager: rewardManager,
    );
    // Note: initialization requires gameDataManager, we will do it below
    
    milestoneManager = MilestoneManager(
      saveManager: gameSaveManager,
      rewardManager: rewardManager,
    );
    // Note: initialization requires gameDataManager, we will do it below
    await achievementManager.initialize([]);
    progressionManager.setDependencies(
      achievementManager: achievementManager,
      milestoneManager: milestoneManager,
    );

    onboardingStorage = OnboardingStorage(saveManager: gameSaveManager);
    onboardingManager = OnboardingManager(storage: onboardingStorage);
    onboardingManager.initialize();

    tutorialManager = TutorialManager(
      saveManager: gameSaveManager,
      dataManager: gameDataManager,
    );
    await tutorialManager.initialize();

    notificationService = StubNotificationService();
    notificationScheduler = NotificationScheduler(
      dailyChallengeManager: dailyChallengeManager,
      eventManager: eventManager,
      rewardManager: rewardManager,
      dateService: dateService,
    );
    notificationStorage = NotificationStorage(saveManager: gameSaveManager);
    notificationManager = NotificationManager(
      service: notificationService,
      scheduler: notificationScheduler,
      storage: notificationStorage,
      settingsManager: settingsManager,
    );
    await notificationManager.initialize();

    adService = StubAdService();
    adConsentManager = StubAdConsentManager();
    adFreeManager = AdFreeManager(saveManager: gameSaveManager);
    adFrequencyController = AdFrequencyController(saveManager: gameSaveManager);
    monetizationManager = MonetizationManager(
      adService: adService,
      consentManager: adConsentManager,
      adFreeManager: adFreeManager,
      frequencyController: adFrequencyController,
      rewardManager: rewardManager,
      onboardingManager: onboardingManager,
    );
    await monetizationManager.initialize();


    securityManager = SecurityManager(
      config: securityConfig,
      gameDataManager: gameDataManager,
      saveManager: gameSaveManager,
      analyticsManager: analyticsManager,
    );
    securityManager.initialize();

    playerProfileManager = PlayerProfileManager(
      saveManager: gameSaveManager,
      analyticsManager: analyticsManager,
    );
    playerProfileManager.initialize();
  }
}
