import 'package:flutter/foundation.dart';
import '../../core/services/date_service.dart';
import '../../core/storage/storage.dart';
import 'daily_challenge_definition.dart';
import 'daily_challenge_progress.dart';
import 'daily_challenge_storage.dart';
import 'daily_challenge_generator.dart';
import 'daily_challenge_type.dart';
import '../../core/services/service_locator.dart';
import '../rewards/reward_definition.dart';
import '../achievements/achievement_event.dart';
import '../../models/block.dart';

class DailyChallengeManager extends ChangeNotifier {
  final DateService dateService;
  final DailyChallengeStorage challengeStorage;
  final GameStorage gameStorage;
  final DailyChallengeGenerator generator;

  DailyChallengeDefinition? _currentChallenge;
  DailyChallengeProgress? _currentProgress;

  DailyChallengeManager({
    required this.dateService,
    required this.challengeStorage,
    required this.gameStorage,
    required this.generator,
  });

  DailyChallengeDefinition? get currentChallenge => _currentChallenge;
  DailyChallengeProgress? get currentProgress => _currentProgress;

  bool get isCompleted => _currentProgress?.completed ?? false;
  bool get isRewardClaimed => _currentProgress?.rewardClaimed ?? false;
  bool get canClaimReward => isCompleted && !isRewardClaimed;

  Future<void> initialize() async {
    final dateKey = dateService.getTodayDateKey();
    
    // Load from storage
    var def = await challengeStorage.loadDefinition();
    var prog = await challengeStorage.loadProgress();

    // If it's empty or from a different day, generate a new one
    if (def == null || def.dateKey != dateKey || prog == null) {
      def = generator.generateForDate(dateKey);
      prog = DailyChallengeProgress(
        challengeId: def.id,
        targetValue: def.primaryTarget,
        targetValue2: def.secondaryTarget,
      );
      await challengeStorage.saveChallenge(def, prog);
    }

    _currentChallenge = def;
    _currentProgress = prog;
    notifyListeners();
  }

  Future<void> onColorBlocksCleared(BlockColor color, int count) async {
    if (_currentChallenge == null || _currentProgress == null) return;
    if (!dateService.isToday(_currentChallenge!.dateKey)) {
      await initialize();
      return;
    }
    if (_currentProgress!.completed) return;

    int new1 = _currentProgress!.currentValue;
    int new2 = _currentProgress!.currentValue2;
    bool updated = false;

    if (_currentChallenge!.primaryColor == color && new1 < _currentChallenge!.primaryTarget) {
      new1 = (new1 + count).clamp(0, _currentChallenge!.primaryTarget);
      updated = true;
    }
    if (_currentChallenge!.secondaryColor == color && new2 < _currentChallenge!.secondaryTarget) {
      new2 = (new2 + count).clamp(0, _currentChallenge!.secondaryTarget);
      updated = true;
    }

    if (!updated) return;

    final bool isCompleted = new1 >= _currentChallenge!.primaryTarget && 
                             new2 >= _currentChallenge!.secondaryTarget;

    _currentProgress = _currentProgress!.copyWith(
      currentValue: new1,
      currentValue2: new2,
      completed: isCompleted,
    );

    await challengeStorage.saveChallenge(_currentChallenge!, _currentProgress!);
    
    if (isCompleted) {
      final evt = ChallengeCompletedEvent(_currentChallenge!.id);
      ServiceLocator.instance.achievementManager.processEvent(evt);
      ServiceLocator.instance.milestoneManager.processEvent(evt);
    }
    
    notifyListeners();
  }

  Future<void> incrementProgress(DailyChallengeType type, [int amount = 1]) async {
    if (_currentChallenge == null || _currentProgress == null) return;
    if (_currentChallenge!.challengeType != type) return;

    if (!dateService.isToday(_currentChallenge!.dateKey)) {
      await initialize();
      return;
    }

    if (_currentProgress!.completed) return;

    final newCurrent = _currentProgress!.currentValue + amount;
    final isCompleted = newCurrent >= _currentChallenge!.target;

    _currentProgress = _currentProgress!.copyWith(
      currentValue: newCurrent,
      completed: isCompleted,
    );

    await challengeStorage.saveChallenge(_currentChallenge!, _currentProgress!);
    
    if (isCompleted) {
      final evt = ChallengeCompletedEvent(_currentChallenge!.id);
      ServiceLocator.instance.achievementManager.processEvent(evt);
      ServiceLocator.instance.milestoneManager.processEvent(evt);
    }
    
    notifyListeners();
  }

  Future<void> updateProgressMax(DailyChallengeType type, int value) async {
    if (_currentChallenge == null || _currentProgress == null) return;
    if (_currentChallenge!.challengeType != type) return;
    if (!dateService.isToday(_currentChallenge!.dateKey)) {
      await initialize();
      return;
    }
    if (_currentProgress!.completed) return;

    if (value > _currentProgress!.currentValue) {
      final isCompleted = value >= _currentChallenge!.target;
      _currentProgress = _currentProgress!.copyWith(
        currentValue: value,
        completed: isCompleted,
      );
      await challengeStorage.saveChallenge(_currentChallenge!, _currentProgress!);
      
      if (isCompleted) {
        final evt = ChallengeCompletedEvent(_currentChallenge!.id);
        ServiceLocator.instance.achievementManager.processEvent(evt);
        ServiceLocator.instance.milestoneManager.processEvent(evt);
      }
      
      notifyListeners();
    }
  }

  Future<bool> claimReward() async {
    if (_currentChallenge == null || _currentProgress == null) return false;
    if (!_currentProgress!.completed || _currentProgress!.rewardClaimed) return false;

    final rewardType = _currentChallenge!.rewardId == 'coins' ? RewardType.coins : RewardType.booster;
    
    final rewardDef = RewardDefinition(
      id: 'reward_${_currentChallenge!.id}',
      type: rewardType,
      amount: _currentChallenge!.rewardAmount,
      itemId: rewardType == RewardType.booster ? _currentChallenge!.rewardId : null,
      source: 'daily_challenge',
    );

    final rewardManager = ServiceLocator.instance.rewardManager;
    final result = await rewardManager.grantReward(rewardDef, uniqueClaimId: _currentChallenge!.id);

    if (result.isSuccess) {
      _currentProgress = _currentProgress!.copyWith(rewardClaimed: true);
      await challengeStorage.saveChallenge(_currentChallenge!, _currentProgress!);
      notifyListeners();
      return true;
    }
    
    return false;
  }
}

