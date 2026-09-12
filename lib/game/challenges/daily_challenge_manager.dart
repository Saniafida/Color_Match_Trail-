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
  int _streak = 1;
  String? _lastCompletedDate;

  DailyChallengeManager({
    required this.dateService,
    required this.challengeStorage,
    required this.gameStorage,
    required this.generator,
  });

  DailyChallengeDefinition? get currentChallenge => _currentChallenge;
  DailyChallengeProgress? get currentProgress => _currentProgress;

  int get streak => _streak;
  int get currentDay => ((_streak - 1) % 7) + 1; // 1 to 7
  String? get lastCompletedDate => _lastCompletedDate;

  bool get isCompleted => _currentProgress?.completed ?? false;
  bool get isRewardClaimed => _currentProgress?.rewardClaimed ?? false;
  bool get canClaimReward => isCompleted && !isRewardClaimed;

  Future<void> initialize({bool force = false}) async {
    final dateKey = dateService.getTodayDateKey();
    if (!force && _currentChallenge != null && _currentChallenge!.dateKey == dateKey && _currentProgress != null) {
      notifyListeners();
      return;
    }
    _streak = challengeStorage.loadStreak();
    _lastCompletedDate = challengeStorage.loadLastCompletedDate();
    
    // Load from storage
    var def = await challengeStorage.loadDefinition();
    var prog = await challengeStorage.loadProgress();

    // Check if new calendar day
    if (def == null || def.dateKey != dateKey || prog == null) {
      if (_lastCompletedDate != null && _lastCompletedDate != dateKey) {
        final yesterday = _getYesterdayDateKey();
        if (_lastCompletedDate == yesterday) {
          // Completed yesterday -> advance streak to next day in 7-day cycle
          if (prog != null && prog.rewardClaimed) {
            _streak = (_streak >= 7) ? 1 : _streak + 1;
          }
        } else {
          // Missed more than a day -> reset to Day 1
          _streak = 1;
        }
      }

      final dayToGenerate = ((_streak - 1) % 7) + 1;
      def = generator.generateForDate(dateKey, dayToGenerate);
      prog = DailyChallengeProgress(
        challengeId: def.id,
        targetValue: def.primaryTarget,
        targetValue2: def.secondaryTarget,
      );
      await challengeStorage.saveChallenge(
        def,
        prog,
        streak: _streak,
        lastCompletedDate: _lastCompletedDate,
      );
    }

    _currentChallenge = def;
    _currentProgress = prog;
    notifyListeners();
  }

  String _getYesterdayDateKey() {
    final yesterday = dateService.now().subtract(const Duration(days: 1));
    final y = yesterday.year.toString();
    final m = yesterday.month.toString().padLeft(2, '0');
    final d = yesterday.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

    await challengeStorage.saveChallenge(
      _currentChallenge!,
      _currentProgress!,
      streak: _streak,
      lastCompletedDate: _lastCompletedDate,
    );
    
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

    await challengeStorage.saveChallenge(
      _currentChallenge!,
      _currentProgress!,
      streak: _streak,
      lastCompletedDate: _lastCompletedDate,
    );
    
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
      await challengeStorage.saveChallenge(
        _currentChallenge!,
        _currentProgress!,
        streak: _streak,
        lastCompletedDate: _lastCompletedDate,
      );
      
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
      _lastCompletedDate = dateService.getTodayDateKey();
      _currentProgress = _currentProgress!.copyWith(rewardClaimed: true);
      await challengeStorage.saveChallenge(
        _currentChallenge!,
        _currentProgress!,
        streak: _streak,
        lastCompletedDate: _lastCompletedDate,
      );

      try {
        ServiceLocator.instance.statisticsManager.onDailyChallengeCompleted();
      } catch (_) {}

      notifyListeners();
      return true;
    }
    
    return false;
  }

  /// Testing helper
  void setStreakForTesting(int streak, {String? lastCompletedDate}) {
    _streak = streak.clamp(1, 7);
    _lastCompletedDate = lastCompletedDate;
    notifyListeners();
  }

  /// Testing helper
  void setProgressForTesting(DailyChallengeProgress progress) {
    _currentProgress = progress;
    notifyListeners();
  }
}
