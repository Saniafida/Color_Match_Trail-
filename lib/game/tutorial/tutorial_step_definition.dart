class TutorialStepDefinition {
  final String stepId;
  final String titleKey;
  final String descriptionKey;
  final String targetType; // 'board', 'booster', 'goal', 'moves', 'combo', 'none'
  final String? targetId; // e.g. color to match, booster id, or specific cell "row,col"
  final String requiredAction; // 'connect', 'blast', 'use_booster', 'continue', 'tap'
  final String highlightType; // 'board', 'booster_bar', 'goal_panel', 'moves_panel', 'overlay'
  final bool optional;
  final bool enabled;

  const TutorialStepDefinition({
    required this.stepId,
    required this.titleKey,
    required this.descriptionKey,
    this.targetType = 'none',
    this.targetId,
    required this.requiredAction,
    this.highlightType = 'overlay',
    this.optional = false,
    this.enabled = true,
  });

  factory TutorialStepDefinition.fromJson(Map<String, dynamic> json) {
    return TutorialStepDefinition(
      stepId: json['stepId'] as String,
      titleKey: json['titleKey'] as String,
      descriptionKey: json['descriptionKey'] as String,
      targetType: json['targetType'] as String? ?? 'none',
      targetId: json['targetId'] as String?,
      requiredAction: json['requiredAction'] as String,
      highlightType: json['highlightType'] as String? ?? 'overlay',
      optional: json['optional'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'targetType': targetType,
      'targetId': targetId,
      'requiredAction': requiredAction,
      'highlightType': highlightType,
      'optional': optional,
      'enabled': enabled,
    };
  }
}
