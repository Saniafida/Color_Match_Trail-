import 'event_type.dart';

class EventDefinition {
  final String id;
  final String name;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final EventType eventType;
  final int target;
  final List<int> levelIds;
  
  final String rewardId; // e.g., 'hammer', 'coins'
  final int rewardAmount;
  final int maxProgress; // To cap progress if needed
  
  final bool enabled;
  final int priority;

  const EventDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.eventType,
    required this.target,
    this.levelIds = const [],
    required this.rewardId,
    required this.rewardAmount,
    this.maxProgress = 0,
    this.enabled = true,
    this.priority = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'eventType': eventType.name,
      'target': target,
      'levelIds': levelIds,
      'rewardId': rewardId,
      'rewardAmount': rewardAmount,
      'maxProgress': maxProgress,
      'enabled': enabled,
      'priority': priority,
    };
  }

  factory EventDefinition.fromJson(Map<String, dynamic> json) {
    return EventDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      eventType: EventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => EventType.score,
      ),
      target: json['target'] as int,
      levelIds: (json['levelIds'] as List<dynamic>?)?.cast<int>() ?? [],
      rewardId: json['rewardId'] as String,
      rewardAmount: json['rewardAmount'] as int,
      maxProgress: json['maxProgress'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
    );
  }
}
