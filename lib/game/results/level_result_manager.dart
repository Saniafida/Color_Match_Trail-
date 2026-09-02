import 'package:flutter/foundation.dart';
import 'level_result.dart';
import 'level_result_state.dart';
import 'star_calculator.dart';
import 'score_calculator.dart';
import 'level_result_validator.dart';
import '../progression/progression_manager.dart';
import '../rewards/reward_manager.dart';
import '../level_result/level_event.dart'; 
import '../level_result/game_status.dart';
import '../../models/level.dart';
import '../../core/services/service_locator.dart';

class LevelResultManager extends ChangeNotifier {
  final ProgressionManager _progressionManager;
  // ignore: unused_field
  final RewardManager _rewardManager;
  
  LevelResultState _state = LevelResultState.completed;
  LevelResult? _currentResult;
  String? _nextLevelId;
  bool _isCampaignComplete = false;
  
  LevelResultManager({
    required ProgressionManager progressionManager,
    required RewardManager rewardManager,
  }) : _progressionManager = progressionManager,
       _rewardManager = rewardManager;

  LevelResultState get state => _state;
  LevelResult? get currentResult => _currentResult;
  String? get nextLevelId => _nextLevelId;
  bool get isCampaignComplete => _isCampaignComplete;

  Future<void> processResult({
    required LevelResultEvent event,
    required LevelDefinition levelData,
    required int highestCombo,
    required int largestBlast,
  }) async {
    final gameplayResult = event.result;
    
    _state = LevelResultState.calculating;
    notifyListeners();

    // 1. Calculate Score
    final isWon = gameplayResult.status == GameStatus.won;
    int baseScore = gameplayResult.finalScore;
    int bonusScore = 0;
    
    if (isWon) {
      bonusScore = FinalScoreCalculator.calculateBonusScore(
        remainingMoves: gameplayResult.remainingMoves,
        largestBlast: largestBlast,
        maxCombo: highestCombo,
      );
    }
    
    int finalScore = FinalScoreCalculator.calculateFinalScore(
      baseScore: baseScore,
      bonusScore: bonusScore,
    );

    // 2. Calculate Stars
    int stars = 0;
    if (isWon) {
      final dataManager = ServiceLocator.instance.gameDataManager;
      final levelDefinitionData = dataManager.getLevel(levelData.id.toString()) ??
          dataManager.getLevel('level_${levelData.id}');
      
      final thresholds = levelDefinitionData?.starThresholds ?? [1000, 2000, 3000];
      stars = StarCalculator.calculateStars(finalScore, thresholds);
    }

    // 3. Create Result Data
    _currentResult = LevelResult(
      levelId: levelData.id.toString().contains('level_') ? levelData.id.toString() : 'level_${levelData.id}',
      completed: isWon,
      finalScore: finalScore,
      stars: stars,
      movesUsed: (levelData.movesLimit ?? 0) - gameplayResult.remainingMoves,
      movesRemaining: gameplayResult.remainingMoves,
      highestCombo: highestCombo,
      largestBlast: largestBlast,
      goalsCompleted: gameplayResult.completedGoals.length,
      bonusScore: bonusScore,
      rewardId: null,
      completedAt: DateTime.now(),
    );

    // 4. Validate
    if (!LevelResultValidator.validate(
      levelId: _currentResult!.levelId,
      score: _currentResult!.finalScore,
      stars: _currentResult!.stars,
      movesUsed: _currentResult!.movesUsed,
      combo: _currentResult!.highestCombo,
      blast: _currentResult!.largestBlast,
    )) {
      _state = LevelResultState.saveError;
      notifyListeners();
      return;
    }

    // 5. Update Progression & Save
    _state = LevelResultState.saving;
    notifyListeners();

    try {
      if (_currentResult!.completed) {
        await _progressionManager.saveLevelResult(
          levelId: _currentResult!.levelId,
          score: _currentResult!.finalScore,
          stars: _currentResult!.stars,
          movesUsed: _currentResult!.movesUsed,
          highestCombo: _currentResult!.highestCombo,
          completed: _currentResult!.completed,
        );

        // Award 1 Gem for completing level
        try {
          await ServiceLocator.instance.gemManager.addGems(1);
        } catch (_) {}

        // Determine if next level exists or campaign complete
        final currentGlobalLevel = _progressionManager.state.currentLevel;
        if (currentGlobalLevel != null && currentGlobalLevel != _currentResult!.levelId) {
          _nextLevelId = currentGlobalLevel;
          _isCampaignComplete = false;
        } else {
          _nextLevelId = null;
          _isCampaignComplete = _progressionManager.isCampaignCompleted;
        }
      } else {
        // Player failed / ran out of moves: Deduct 1 life!
        await ServiceLocator.instance.livesManager.consumeLife();
      }
      
      _state = LevelResultState.saved;
    } catch (e) {
      _state = LevelResultState.saveError;
    }

    notifyListeners();
  }
  
  void acknowledgeResult() {
    _state = LevelResultState.displaying;
    notifyListeners();
  }

  void reset() {
    _state = LevelResultState.completed;
    _currentResult = null;
    _nextLevelId = null;
    _isCampaignComplete = false;
  }
}
