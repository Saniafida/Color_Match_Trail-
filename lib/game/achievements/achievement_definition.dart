import 'achievement_category.dart';

class AchievementDefinition {
  final String achievementId;
  final String titleKey;
  final String descriptionKey;
  final String iconAsset;
  final AchievementCategory category;
  final String targetType;
  final int targetValue;
  final String? rewardId;
  final bool enabled;

  const AchievementDefinition({
    required this.achievementId,
    required this.titleKey,
    required this.descriptionKey,
    required this.iconAsset,
    required this.category,
    required this.targetType,
    required this.targetValue,
    this.rewardId,
    this.enabled = true,
  });

  factory AchievementDefinition.fromJson(Map<String, dynamic> json) {
    return AchievementDefinition(
      achievementId: json['achievementId'] as String,
      titleKey: json['titleKey'] as String,
      descriptionKey: json['descriptionKey'] as String,
      iconAsset: json['iconAsset'] as String? ?? 'assets/images/achievements/default.png',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.all,
      ),
      targetType: json['targetType'] as String,
      targetValue: json['targetValue'] as int? ?? 1,
      rewardId: json['rewardId'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'iconAsset': iconAsset,
      'category': category.name,
      'targetType': targetType,
      'targetValue': targetValue,
      'rewardId': rewardId,
      'enabled': enabled,
    };
  }
}
