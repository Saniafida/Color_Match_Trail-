enum AchievementCategory {
  all,
  progression,
  skill,
  combo,
  collection,
  booster,
  challenge,
  event,
  special
}

extension AchievementCategoryExtension on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.all: return 'All';
      case AchievementCategory.progression: return 'Progression';
      case AchievementCategory.skill: return 'Skill';
      case AchievementCategory.combo: return 'Combo';
      case AchievementCategory.collection: return 'Collection';
      case AchievementCategory.booster: return 'Booster';
      case AchievementCategory.challenge: return 'Challenge';
      case AchievementCategory.event: return 'Event';
      case AchievementCategory.special: return 'Special';
    }
  }
}
