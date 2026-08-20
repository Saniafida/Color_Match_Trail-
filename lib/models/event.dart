import 'reward.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int progress;
  final int target;
  final List<Reward> rewards;
  final Map<String, dynamic> metadata;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    this.progress = 0,
    required this.target,
    this.rewards = const [],
    this.metadata = const {},
  }) : assert(target >= 0, 'target cannot be negative'),
       assert(progress >= 0, 'progress cannot be negative');

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? progress,
    int? target,
    List<Reward>? rewards,
    Map<String, dynamic>? metadata,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      rewards: rewards ?? this.rewards,
      metadata: metadata ?? this.metadata,
    );
  }
}
