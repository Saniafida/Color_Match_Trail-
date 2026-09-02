class PlayerSaveData {
  final int saveVersion;
  final Map<String, dynamic> campaignProgress;
  final int coins;
  final int gems;
  final Map<String, dynamic> boosterInventory;
  final Map<String, dynamic> dailyChallengeState;
  final Map<String, dynamic> eventProgress;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> statistics;
  final Map<String, dynamic> achievements;
  final Map<String, dynamic> milestones;
  final Map<String, dynamic> onboarding;
  final Map<String, dynamic> scheduledNotifications;
  final Map<String, dynamic> monetization;
  final Map<String, dynamic> analytics;
  final Map<String, dynamic> profile;

  const PlayerSaveData({
    required this.saveVersion,
    this.campaignProgress = const {},
    this.coins = 0,
    this.gems = 0,
    this.boosterInventory = const {},
    this.dailyChallengeState = const {},
    this.eventProgress = const {},
    this.settings = const {},
    this.statistics = const {},
    this.achievements = const {},
    this.milestones = const {},
    this.onboarding = const {},
    this.scheduledNotifications = const {},
    this.monetization = const {},
    this.analytics = const {},
    this.profile = const {},
  });

  PlayerSaveData copyWith({
    int? saveVersion,
    Map<String, dynamic>? campaignProgress,
    int? coins,
    int? gems,
    Map<String, dynamic>? boosterInventory,
    Map<String, dynamic>? dailyChallengeState,
    Map<String, dynamic>? eventProgress,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? statistics,
    Map<String, dynamic>? achievements,
    Map<String, dynamic>? milestones,
    Map<String, dynamic>? onboarding,
    Map<String, dynamic>? scheduledNotifications,
    Map<String, dynamic>? monetization,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? profile,
  }) {
    return PlayerSaveData(
      saveVersion: saveVersion ?? this.saveVersion,
      campaignProgress: campaignProgress ?? this.campaignProgress,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      boosterInventory: boosterInventory ?? this.boosterInventory,
      dailyChallengeState: dailyChallengeState ?? this.dailyChallengeState,
      eventProgress: eventProgress ?? this.eventProgress,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
      achievements: achievements ?? this.achievements,
      milestones: milestones ?? this.milestones,
      onboarding: onboarding ?? this.onboarding,
      scheduledNotifications: scheduledNotifications ?? this.scheduledNotifications,
      monetization: monetization ?? this.monetization,
      analytics: analytics ?? this.analytics,
      profile: profile ?? this.profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saveVersion': saveVersion,
      'campaignProgress': campaignProgress,
      'coins': coins,
      'gems': gems,
      'boosterInventory': boosterInventory,
      'dailyChallengeState': dailyChallengeState,
      'eventProgress': eventProgress,
      'settings': settings,
      'statistics': statistics,
      'achievements': achievements,
      'milestones': milestones,
      'onboarding': onboarding,
      'scheduledNotifications': scheduledNotifications,
      'monetization': monetization,
      'analytics': analytics,
      'profile': profile,
    };
  }

  factory PlayerSaveData.fromJson(Map<String, dynamic> json) {
    return PlayerSaveData(
      saveVersion: json['saveVersion'] as int? ?? 1,
      campaignProgress: json['campaignProgress'] as Map<String, dynamic>? ?? {},
      coins: json['coins'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      boosterInventory: json['boosterInventory'] as Map<String, dynamic>? ?? {},
      dailyChallengeState: json['dailyChallengeState'] as Map<String, dynamic>? ?? {},
      eventProgress: json['eventProgress'] as Map<String, dynamic>? ?? {},
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      statistics: json['statistics'] as Map<String, dynamic>? ?? {},
      achievements: json['achievements'] as Map<String, dynamic>? ?? {},
      milestones: json['milestones'] as Map<String, dynamic>? ?? {},
      onboarding: json['onboarding'] as Map<String, dynamic>? ?? {},
      scheduledNotifications: json['scheduledNotifications'] as Map<String, dynamic>? ?? {},
      monetization: json['monetization'] as Map<String, dynamic>? ?? {},
      analytics: json['analytics'] as Map<String, dynamic>? ?? {},
      profile: json['profile'] as Map<String, dynamic>? ?? {},
    );
  }
}
