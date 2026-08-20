/// Strongly typed wrapper for lifetime gameplay stats.
class PlayerStatistics {
  final int gamesPlayed;
  final int gamesWon;
  final int totalStars;
  final int totalScore;
  final int highestCombo;
  final int boostersUsed;

  const PlayerStatistics({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.totalStars = 0,
    this.totalScore = 0,
    this.highestCombo = 0,
    this.boostersUsed = 0,
  });

  factory PlayerStatistics.fromMap(Map<String, dynamic> map) {
    return PlayerStatistics(
      gamesPlayed: map['gamesPlayed'] as int? ?? 0,
      gamesWon: map['gamesWon'] as int? ?? 0,
      totalStars: map['totalStars'] as int? ?? 0,
      totalScore: map['totalScore'] as int? ?? 0,
      highestCombo: map['highestCombo'] as int? ?? 0,
      boostersUsed: map['boostersUsed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'totalStars': totalStars,
      'totalScore': totalScore,
      'highestCombo': highestCombo,
      'boostersUsed': boostersUsed,
    };
  }

  PlayerStatistics copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? totalStars,
    int? totalScore,
    int? highestCombo,
    int? boostersUsed,
  }) {
    return PlayerStatistics(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      totalStars: totalStars ?? this.totalStars,
      totalScore: totalScore ?? this.totalScore,
      highestCombo: highestCombo ?? this.highestCombo,
      boostersUsed: boostersUsed ?? this.boostersUsed,
    );
  }
}
