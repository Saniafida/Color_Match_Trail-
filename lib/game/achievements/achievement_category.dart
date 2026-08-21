enum AchievementCategory {
  all,
  progression,
  skill,
  combo,
  collection,
  booster,
  challenge,
  event,
  special,
  levels,
  stars,
  blasts,
  boosters,
  worlds
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
      case AchievementCategory.levels: return 'Levels';
      case AchievementCategory.stars: return 'Stars';
      case AchievementCategory.blasts: return 'Blasts';
      case AchievementCategory.boosters: return 'Boosters';
      case AchievementCategory.worlds: return 'Worlds';
    }
  }
}
