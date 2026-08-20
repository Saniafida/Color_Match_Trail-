class ChallengeDefinition {
  final String challengeId;
  final String titleKey;
  final String descriptionKey;
  final String objective;
  final int target;
  final String rewardId;
  final String activeRule; // e.g. "monday", "weekend", "any"

  const ChallengeDefinition({
    required this.challengeId,
    required this.titleKey,
    required this.descriptionKey,
    required this.objective,
    required this.target,
    required this.rewardId,
    this.activeRule = 'any',
  });

  factory ChallengeDefinition.fromJson(Map<String, dynamic> json) {
    return ChallengeDefinition(
      challengeId: json['challengeId'] as String,
      titleKey: json['titleKey'] as String? ?? '',
      descriptionKey: json['descriptionKey'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      target: json['target'] as int? ?? 1,
      rewardId: json['rewardId'] as String? ?? '',
      activeRule: json['activeRule'] as String? ?? 'any',
    );
  }
}
