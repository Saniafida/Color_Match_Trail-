import 'tutorial_step_definition.dart';

class TutorialDefinition {
  final String tutorialId;
  final int version;
  final String? levelId; // Null if it can happen anywhere
  final String? rewardId;
  final bool enabled;
  final List<TutorialStepDefinition> steps;

  const TutorialDefinition({
    required this.tutorialId,
    required this.version,
    this.levelId,
    this.rewardId,
    this.enabled = true,
    required this.steps,
  });

  factory TutorialDefinition.fromJson(Map<String, dynamic> json) {
    var stepsList = json['steps'] as List<dynamic>? ?? [];
    List<TutorialStepDefinition> parsedSteps = stepsList
        .map((e) => TutorialStepDefinition.fromJson(e as Map<String, dynamic>))
        .toList();

    return TutorialDefinition(
      tutorialId: json['tutorialId'] as String,
      version: json['version'] as int? ?? 1,
      levelId: json['levelId'] as String?,
      rewardId: json['rewardId'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      steps: parsedSteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tutorialId': tutorialId,
      'version': version,
      'levelId': levelId,
      'rewardId': rewardId,
      'enabled': enabled,
      'steps': steps.map((e) => e.toJson()).toList(),
    };
  }
}
