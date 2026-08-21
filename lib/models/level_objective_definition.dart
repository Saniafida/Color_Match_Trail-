/// Defines a specific objective/goal configuration for a level in Module 55.
enum LevelObjectiveType {
  clearColor,
  clearBlocks,
  createSpecial,
  createBlast,
  reachScore,
  comboCount,
}

class LevelObjectiveDefinition {
  final String id;
  final LevelObjectiveType objectiveType;
  final String? target; // e.g. 'red', 'bomb', 'line'
  final int targetValue; // amount required
  final int priority; // 1 = highest priority
  final bool enabled;

  const LevelObjectiveDefinition({
    required this.id,
    required this.objectiveType,
    this.target,
    required this.targetValue,
    this.priority = 1,
    this.enabled = true,
  });

  factory LevelObjectiveDefinition.fromJson(Map<String, dynamic> json) {
    return LevelObjectiveDefinition(
      id: json['id'] as String? ?? 'obj_${DateTime.now().millisecondsSinceEpoch}',
      objectiveType: LevelObjectiveType.values.firstWhere(
        (e) => e.name == json['type'] || e.name == json['objectiveType'],
        orElse: () => LevelObjectiveType.clearColor,
      ),
      target: json['target']?.toString(),
      targetValue: json['targetValue'] as int? ?? json['targetAmount'] as int? ?? 1,
      priority: json['priority'] as int? ?? 1,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': objectiveType.name,
      if (target != null) 'target': target,
      'targetValue': targetValue,
      'priority': priority,
      'enabled': enabled,
    };
  }
}
