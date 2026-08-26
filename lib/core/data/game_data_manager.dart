import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/error_reporting/error_reporting_manager.dart';
import '../services/error_reporting/error_category.dart';
import '../services/error_reporting/error_severity.dart';
import '../../models/data/level_definition.dart';
import '../../models/data/world_definition.dart';
import '../../models/data/challenge_definition.dart';
import '../../game/events/event_definition.dart';
import '../../game/shop/shop_item_definition.dart';
import '../../game/achievements/achievement_definition.dart';
import '../../game/achievements/milestone_definition.dart';
import 'game_data_status.dart';
import 'game_data_validator.dart';
import 'game_data_migration_manager.dart';
import 'game_balance_config.dart';
import 'data_environment.dart';
import '../../game/levels/adventure_level_generator.dart';

/// Central data gateway for the completely offline game.
/// Loads data directly from bundled JSON assets in assets/data/
class GameDataManager extends ChangeNotifier {
  final ErrorReportingManager _errorReportingManager;

  final GameDataValidator _validator = GameDataValidator();
  final GameDataMigrationManager _migrationManager = GameDataMigrationManager();

  GameDataStatus _status = GameDataStatus.notLoaded;
  GameDataStatus get status => _status;

  late GameBalanceConfig _balanceConfig;
  GameBalanceConfig get balanceConfig => _balanceConfig;

  final Map<String, WorldDefinition> _worlds = {};
  final Map<String, LevelDefinitionData> _levels = {};
  final Map<String, ChallengeDefinition> _challenges = {};
  final Map<String, EventDefinition> _events = {};
  final Map<String, ShopItemDefinition> _shopItems = {};
  final Map<String, AchievementDefinition> _achievements = {};
  final Map<String, MilestoneDefinition> _milestones = {};

  GameDataValidationResult? _lastValidationResult;
  GameDataValidationResult? get lastValidationResult => _lastValidationResult;

  GameDataManager({
    required ErrorReportingManager errorReportingManager,
  }) : _errorReportingManager = errorReportingManager {
    _balanceConfig = DataEnvironmentExtension.current.isDevelopment
        ? GameBalanceConfig.development
        : GameBalanceConfig.production;
  }

  Future<void> initialize() async {
    if (_status == GameDataStatus.loaded) return;

    _status = GameDataStatus.loading;
    notifyListeners();

    try {
      // 1. Load Worlds
      await _loadAndParseList('assets/data/worlds/worlds.json', (json) {
        final world = WorldDefinition.fromJson(json);
        _worlds[world.worldId] = world;
      });

      // Ensure all 147 adventure levels are mapped across worlds
      final adventureWorlds = AdventureLevelGenerator.generateAllWorlds();
      for (final w in adventureWorlds) {
        _worlds.putIfAbsent(w.worldId, () => w);
      }

      // 2. Load Levels
      await _loadAndParseList('assets/data/levels/levels.json', (json) {
        final level = LevelDefinitionData.fromJson(json);
        _levels[level.levelId] = level;
      });

      // Populate procedural data for all 147 levels
      for (int i = 1; i <= AdventureLevelGenerator.totalAdventureLevels; i++) {
        final lvlId = 'level_$i';
        _levels.putIfAbsent(lvlId, () => AdventureLevelGenerator.generateData(i));
      }

      // 2. Load Challenges
      await _loadAndParseList('assets/data/challenges/challenges.json', (json) {
        final challenge = ChallengeDefinition.fromJson(json);
        _challenges[challenge.challengeId] = challenge;
      });

      // 3. Load Events
      await _loadAndParseList('assets/data/events/events.json', (json) {
        final event = EventDefinition.fromJson(json);
        _events[event.id] = event;
      });

      // 4. Load Shop
      await _loadAndParseList('assets/data/shop/shop.json', (json) {
        final shopItem = ShopItemDefinition.fromJson(json);
        _shopItems[shopItem.id] = shopItem;
      });

      // 5. Load Achievements
      await _loadAndParseList('assets/data/achievements/achievements.json', (json) {
        final ach = AchievementDefinition.fromJson(json);
        _achievements[ach.achievementId] = ach;
      });

      // 6. Load Milestones
      await _loadAndParseList('assets/data/milestones/milestones.json', (json) {
        final m = MilestoneDefinition.fromJson(json);
        _milestones[m.milestoneId] = m;
      });

      // 7. Check schema migrations (for local saving, though static data rarely needs this unless mapping to saves changes)
      for (final level in _levels.values) {
        _migrationManager.checkVersion(1, level.levelId); // Dummy check for architectural completeness
      }

      // 6. Validate
      final levelsResult = _validator.validateLevels(_levels.values.toList());
      final challengesResult = _validator.validateChallenges(_challenges.values.toList());
      final eventsResult = _validator.validateEvents(_events.values.toList());
      final shopResult = _validator.validateShop(_shopItems.values.toList());

      _lastValidationResult = _validator.merge([
        levelsResult,
        challengesResult,
        eventsResult,
        shopResult,
      ]);

      if (!_lastValidationResult!.isValid) {
        for (final error in _lastValidationResult!.errors) {
          await _errorReportingManager.reportException(
            Exception('GameData validation error: $error'),
            null,
            category: ErrorCategory.loading,
            severity: ErrorSeverity.warning,
            module: 'GameDataManager',
          );
        }
      }

      _status = GameDataStatus.loaded;
    } catch (e, st) {
      _status = GameDataStatus.failed;
      await _errorReportingManager.reportException(
        e,
        st,
        category: ErrorCategory.loading,
        severity: ErrorSeverity.nonFatal,
        module: 'GameDataManager',
      );
    }

    notifyListeners();
  }

  Future<void> _loadAndParseList(String assetPath, void Function(Map<String, dynamic>) onParse) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            onParse(item);
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        onParse(decoded);
      }
    } catch (e) {
      debugPrint('[GameDataManager] Failed to load $assetPath: $e');
      // Intentionally swallowed so one missing file doesn't crash the entire game.
    }
  }

  WorldDefinition? getWorld(String id) {
    if (_worlds.containsKey(id)) return _worlds[id];
    final all = AdventureLevelGenerator.generateAllWorlds();
    for (final w in all) {
      if (w.worldId == id) {
        _worlds[id] = w;
        return w;
      }
    }
    return null;
  }

  List<WorldDefinition> getAllWorlds() {
    if (_worlds.isEmpty) {
      final all = AdventureLevelGenerator.generateAllWorlds();
      for (final w in all) {
        _worlds[w.worldId] = w;
      }
    }
    return _worlds.values.toList();
  }

  LevelDefinitionData? getLevel(String levelId) {
    if (_levels.containsKey(levelId)) return _levels[levelId];
    final num = int.tryParse(levelId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (num != null && num >= 1) {
      final generated = AdventureLevelGenerator.generateData(num);
      _levels[levelId] = generated;
      return generated;
    }
    return null;
  }
  List<LevelDefinitionData> getAllLevels() => _levels.values.toList();
  
  ChallengeDefinition? getChallenge(String id) => _challenges[id];
  List<ChallengeDefinition> getAllChallenges() => _challenges.values.toList();
  
  EventDefinition? getEvent(String id) => _events[id];
  List<EventDefinition> getAllEvents() => _events.values.toList();

  ShopItemDefinition? getShopItem(String id) => _shopItems[id];
  List<ShopItemDefinition> getAllShopItems() => _shopItems.values.toList();

  AchievementDefinition? getAchievement(String id) => _achievements[id];
  List<AchievementDefinition> getAllAchievements() => _achievements.values.toList();

  MilestoneDefinition? getMilestone(String id) => _milestones[id];
  List<MilestoneDefinition> getAllMilestones() => _milestones.values.toList();

  GameBalanceConfig getBalanceConfig() => _balanceConfig;

  void applyBalanceConfig(GameBalanceConfig config) {
    if (DataEnvironmentExtension.current.isProduction) {
      _balanceConfig = config.copyWith(
        devUnlimitedCoins: false,
        devUnlockAllLevels: false,
        devUnlimitedBoosters: false,
        devFastAnimations: false,
      );
    } else {
      _balanceConfig = config;
    }
    notifyListeners();
  }

  bool get isLoaded => _status == GameDataStatus.loaded;
  bool get isFailed => _status == GameDataStatus.failed;
  bool get isLoading => _status == GameDataStatus.loading;
}
