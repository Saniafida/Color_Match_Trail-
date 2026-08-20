import 'player_statistics.dart';

/// The core identity and progression summary of a player.
class PlayerProfile {
  final String playerId;
  final String displayName;
  final String avatarId;
  final int playerLevel;
  final int xp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlayerStatistics statistics;

  const PlayerProfile({
    required this.playerId,
    required this.displayName,
    required this.avatarId,
    this.playerLevel = 1,
    this.xp = 0,
    required this.createdAt,
    required this.updatedAt,
    this.statistics = const PlayerStatistics(),
  });

  PlayerProfile copyWith({
    String? displayName,
    String? avatarId,
    int? playerLevel,
    int? xp,
    DateTime? updatedAt,
    PlayerStatistics? statistics,
  }) {
    return PlayerProfile(
      playerId: playerId, // playerId should never change via copyWith
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      playerLevel: playerLevel ?? this.playerLevel,
      xp: xp ?? this.xp,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statistics: statistics ?? this.statistics,
    );
  }
}
