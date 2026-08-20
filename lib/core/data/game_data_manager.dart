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
import 'game_data_status.dart';
import 'game_data_validator.dart';
import 'game_data_migration_manager.dart';
import 'game_balance_config.dart';
import 'data_environment.dart';

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

      // 2. Load Levels
      await _loadAndParseList('assets/data/levels/levels.json', (json) {
        final level = LevelDefinitionData.fromJson(json);
        _levels[level.levelId] = level;
      });

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

      // 5. Check schema migrations (for local saving, though static data rarely needs this unless mapping to saves changes)
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

  WorldDefinition? getWorld(String id) => _worlds[id];
  List<WorldDefinition> getAllWorlds() => _worlds.values.toList();

  LevelDefinitionData? getLevel(String levelId) => _levels[levelId];
  List<LevelDefinitionData> getAllLevels() => _levels.values.toList();
  
  ChallengeDefinition? getChallenge(String id) => _challenges[id];
  List<ChallengeDefinition> getAllChallenges() => _challenges.values.toList();
  
  EventDefinition? getEvent(String id) => _events[id];
  List<EventDefinition> getAllEvents() => _events.values.toList();

  ShopItemDefinition? getShopItem(String id) => _shopItems[id];
  List<ShopItemDefinition> getAllShopItems() => _shopItems.values.toList();

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
