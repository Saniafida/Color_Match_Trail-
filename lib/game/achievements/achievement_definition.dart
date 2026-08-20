import 'achievement_category.dart';
import 'achievement_type.dart';

class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementType achievementType;
  final int targetValue;
  final String? rewardId;
  final int rewardAmount;
  final bool hidden;
  final bool enabled;

  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.achievementType,
    required this.targetValue,
    this.rewardId,
    this.rewardAmount = 0,
    this.hidden = false,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category.name,
      'achievementType': achievementType.name,
      'targetValue': targetValue,
      'rewardId': rewardId,
      'rewardAmount': rewardAmount,
      'hidden': hidden,
      'enabled': enabled,
    };
  }
}
