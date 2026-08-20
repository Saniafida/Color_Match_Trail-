import 'reward.dart';

enum ChallengeType {
  completeLevels,
  collectBlocks,
  useBoosters,
  winLevels,
  earnStars,
  completeWithoutBooster
}

class DailyChallenge {
  final String id;
  final ChallengeType type;
  final int target;
  final int progress;
  final Reward reward;
  final bool isCompleted;
  final bool isClaimed;
  final DateTime startDate;
  final DateTime endDate;

  const DailyChallenge({
    required this.id,
    required this.type,
    required this.target,
    this.progress = 0,
    required this.reward,
    this.isCompleted = false,
    this.isClaimed = false,
    required this.startDate,
    required this.endDate,
  }) : assert(target >= 0, 'target cannot be negative'),
       assert(progress >= 0, 'progress cannot be negative');

  DailyChallenge copyWith({
    String? id,
    ChallengeType? type,
    int? target,
    int? progress,
    Reward? reward,
    bool? isCompleted,
    bool? isClaimed,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      type: type ?? this.type,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      reward: reward ?? this.reward,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
