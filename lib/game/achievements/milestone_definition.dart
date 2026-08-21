class MilestoneDefinition {
  final String milestoneId;
  final String titleKey;
  final String descriptionKey;
  final String targetType;
  final int targetValue;
  final String? rewardId;
  final bool enabled;

  const MilestoneDefinition({
    required this.milestoneId,
    required this.titleKey,
    required this.descriptionKey,
    required this.targetType,
    required this.targetValue,
    this.rewardId,
    this.enabled = true,
  });

  factory MilestoneDefinition.fromJson(Map<String, dynamic> json) {
    return MilestoneDefinition(
      milestoneId: json['milestoneId'] as String,
      titleKey: json['titleKey'] as String,
      descriptionKey: json['descriptionKey'] as String,
      targetType: json['targetType'] as String,
      targetValue: json['targetValue'] as int? ?? 1,
      rewardId: json['rewardId'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'milestoneId': milestoneId,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'targetType': targetType,
      'targetValue': targetValue,
      'rewardId': rewardId,
      'enabled': enabled,
    };
  }
}
