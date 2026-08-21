import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/data/game_balance_config.dart';
import '../../models/difficulty_definition.dart';
import 'difficulty_manager.dart';
import 'difficulty_tier.dart';

class GameBalanceManager extends ChangeNotifier {
  final DifficultyManager difficultyManager = const DifficultyManager();

  GameBalanceConfig _config = GameBalanceConfig.production;
  GameBalanceConfig get config => _config;

  final Map<String, DifficultyDefinition> _difficultyDefinitions = {};
  Map<String, DifficultyDefinition> get difficultyDefinitions => Map.unmodifiable(_difficultyDefinitions);

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      // 1. Load game balance JSON if available
      try {
        final balanceJsonStr = await rootBundle.loadString('assets/data/balance/game_balance.json');
        final dynamic balanceData = jsonDecode(balanceJsonStr);
        if (balanceData is Map<String, dynamic>) {
          _config = _parseConfig(balanceData);
        }
      } catch (_) {
        // Fallback to production default
        _config = GameBalanceConfig.production;
      }

      // 2. Load difficulty definitions JSON if available
      try {
        final diffJsonStr = await rootBundle.loadString('assets/data/balance/difficulty.json');
        final dynamic diffData = jsonDecode(diffJsonStr);
        if (diffData is List) {
          for (final item in diffData) {
            if (item is Map<String, dynamic>) {
              final def = DifficultyDefinition.fromJson(item);
              _difficultyDefinitions[def.tier] = def;
            }
          }
        }
      } catch (_) {
        // Provide standard in-memory defaults
        _populateDefaultDifficultyDefinitions();
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('[GameBalanceManager] Error initializing: $e');
      _populateDefaultDifficultyDefinitions();
      _isLoaded = true;
    }
  }

  void _populateDefaultDifficultyDefinitions() {
    _difficultyDefinitions['easy'] = const DifficultyDefinition(
      tier: 'easy',
      minColors: 3,
      maxColors: 4,
      minMoves: 25,
      maxMoves: 35,
      baseScoreMultiplier: 1,
      estimatedClearRate: 0.95,
      complexityWeight: 1.0,
    );
    _difficultyDefinitions['normal'] = const DifficultyDefinition(
      tier: 'normal',
      minColors: 4,
      maxColors: 5,
      minMoves: 20,
      maxMoves: 30,
      baseScoreMultiplier: 2,
      estimatedClearRate: 0.80,
      complexityWeight: 1.5,
    );
    _difficultyDefinitions['hard'] = const DifficultyDefinition(
      tier: 'hard',
      minColors: 4,
      maxColors: 5,
      minMoves: 18,
      maxMoves: 28,
      baseScoreMultiplier: 3,
      estimatedClearRate: 0.60,
      complexityWeight: 2.2,
    );
    _difficultyDefinitions['expert'] = const DifficultyDefinition(
      tier: 'expert',
      minColors: 5,
      maxColors: 6,
      minMoves: 15,
      maxMoves: 25,
      baseScoreMultiplier: 4,
      estimatedClearRate: 0.40,
      complexityWeight: 3.0,
    );
  }

  GameBalanceConfig _parseConfig(Map<String, dynamic> json) {
    return GameBalanceConfig(
      baseScorePerBlock: json['baseScorePerBlock'] as int? ?? _config.baseScorePerBlock,
      comboMultiplierStep: (json['comboMultiplierStep'] as num?)?.toDouble() ?? _config.comboMultiplierStep,
      maxComboMultiplier: json['maxComboMultiplier'] as int? ?? _config.maxComboMultiplier,
      scorePerStar: json['scorePerStar'] as int? ?? _config.scorePerStar,
      minMatchLength: json['minMatchLength'] as int? ?? _config.minMatchLength,
      bigMatchThreshold: json['bigMatchThreshold'] as int? ?? _config.bigMatchThreshold,
      largeMatchThreshold: json['largeMatchThreshold'] as int? ?? _config.largeMatchThreshold,
      blastMinBlocks: json['blastMinBlocks'] as int? ?? _config.blastMinBlocks,
      comboWindowMs: json['comboWindowMs'] as int? ?? _config.comboWindowMs,
      comboLevel2Threshold: json['comboLevel2Threshold'] as int? ?? _config.comboLevel2Threshold,
      comboLevel3Threshold: json['comboLevel3Threshold'] as int? ?? _config.comboLevel3Threshold,
      star1ScorePercent: json['star1ScorePercent'] as int? ?? _config.star1ScorePercent,
      star2ScorePercent: json['star2ScorePercent'] as int? ?? _config.star2ScorePercent,
      star3ScorePercent: json['star3ScorePercent'] as int? ?? _config.star3ScorePercent,
      dailyChallengeCompletionCoins: json['dailyChallengeCompletionCoins'] as int? ?? _config.dailyChallengeCompletionCoins,
      levelFirstStarCoins: json['levelFirstStarCoins'] as int? ?? _config.levelFirstStarCoins,
      levelThreeStarBonusCoins: json['levelThreeStarBonusCoins'] as int? ?? _config.levelThreeStarBonusCoins,
      achievementBaseCoins: json['achievementBaseCoins'] as int? ?? _config.achievementBaseCoins,
      hammerCoinCost: json['hammerCoinCost'] as int? ?? _config.hammerCoinCost,
      shuffleCoinCost: json['shuffleCoinCost'] as int? ?? _config.shuffleCoinCost,
      rowClearCoinCost: json['rowClearCoinCost'] as int? ?? _config.rowClearCoinCost,
      colorClearCoinCost: json['colorClearCoinCost'] as int? ?? _config.colorClearCoinCost,
      extraMovesCoinCost: json['extraMovesCoinCost'] as int? ?? _config.extraMovesCoinCost,
      extraMovesGranted: json['extraMovesGranted'] as int? ?? _config.extraMovesGranted,
      specialBlockSpawnChance: (json['specialBlockSpawnChance'] as num?)?.toDouble() ?? _config.specialBlockSpawnChance,
      maxColorsOnBoard: json['maxColorsOnBoard'] as int? ?? _config.maxColorsOnBoard,
    );
  }

  /// Apply a testing preset (only active in development)
  void applyDifficultyPreset(DifficultyTier tier) {
    if (kReleaseMode) return;

    switch (tier) {
      case DifficultyTier.easy:
        _config = _config.copyWith(
          baseScorePerBlock: 20,
          comboMultiplierStep: 1.0,
          specialBlockSpawnChance: 0.15,
          maxColorsOnBoard: 3,
        );
        break;
      case DifficultyTier.normal:
        _config = GameBalanceConfig.production;
        break;
      case DifficultyTier.hard:
        _config = _config.copyWith(
          baseScorePerBlock: 10,
          comboMultiplierStep: 0.3,
          specialBlockSpawnChance: 0.02,
          maxColorsOnBoard: 5,
        );
        break;
      case DifficultyTier.expert:
        _config = _config.copyWith(
          baseScorePerBlock: 8,
          comboMultiplierStep: 0.2,
          specialBlockSpawnChance: 0.01,
          maxColorsOnBoard: 6,
        );
        break;
    }
    notifyListeners();
  }

  DifficultyDefinition? getDifficultyDefinition(String tier) => _difficultyDefinitions[tier.toLowerCase()];
}
