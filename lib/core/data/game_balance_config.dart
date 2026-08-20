/// Centralized balance configuration for all tunable gameplay values.
///
/// Instead of scattering magic numbers throughout widgets and controllers,
/// systems should read from this class. Values can be tuned here without
/// touching gameplay logic.
///
/// Future: these values can be overridden by a RemoteConfigService.
class GameBalanceConfig {
  // ---- Scoring ----
  final int baseScorePerBlock;
  final double comboMultiplierStep;
  final int maxComboMultiplier;
  final int scorePerStar;

  // ---- Matching ----
  final int minMatchLength;
  final int bigMatchThreshold;   // >= this count triggers "big match" audio/visual
  final int largeMatchThreshold; // >= this count triggers maximum escalation

  // ---- Blasting ----
  final int blastMinBlocks;      // minimum blocks for a blast to occur

  // ---- Combos ----
  final int comboWindowMs;       // ms window in which cascades count as combo
  final int comboLevel2Threshold;
  final int comboLevel3Threshold;

  // ---- Star Thresholds (default, levels may override) ----
  final int star1ScorePercent; // % of target score for 1 star
  final int star2ScorePercent; // % for 2 stars
  final int star3ScorePercent; // % for 3 stars (usually 100%)

  // ---- Rewards ----
  final int dailyChallengeCompletionCoins;
  final int levelFirstStarCoins;
  final int levelThreeStarBonusCoins;
  final int achievementBaseCoins;

  // ---- Boosters ----
  final int hammerCoinCost;
  final int shuffleCoinCost;
  final int rowClearCoinCost;
  final int colorClearCoinCost;
  final int extraMovesCoinCost;
  final int extraMovesGranted;   // how many moves "+5 Moves" booster adds

  // ---- Spawn ----
  final double specialBlockSpawnChance; // 0.0–1.0
  final int maxColorsOnBoard;

  // ---- Development Overrides (ignored in production) ----
  final bool devUnlimitedCoins;
  final bool devUnlockAllLevels;
  final bool devUnlimitedBoosters;
  final bool devFastAnimations;

  const GameBalanceConfig({
    // Scoring
    this.baseScorePerBlock = 10,
    this.comboMultiplierStep = 0.5,
    this.maxComboMultiplier = 4,
    this.scorePerStar = 100,

    // Matching
    this.minMatchLength = 3,
    this.bigMatchThreshold = 5,
    this.largeMatchThreshold = 7,

    // Blasting
    this.blastMinBlocks = 3,

    // Combos
    this.comboWindowMs = 1500,
    this.comboLevel2Threshold = 2,
    this.comboLevel3Threshold = 3,

    // Stars
    this.star1ScorePercent = 50,
    this.star2ScorePercent = 75,
    this.star3ScorePercent = 100,

    // Rewards
    this.dailyChallengeCompletionCoins = 50,
    this.levelFirstStarCoins = 20,
    this.levelThreeStarBonusCoins = 30,
    this.achievementBaseCoins = 100,

    // Boosters
    this.hammerCoinCost = 50,
    this.shuffleCoinCost = 75,
    this.rowClearCoinCost = 100,
    this.colorClearCoinCost = 150,
    this.extraMovesCoinCost = 200,
    this.extraMovesGranted = 5,

    // Spawn
    this.specialBlockSpawnChance = 0.05,
    this.maxColorsOnBoard = 5,

    // Dev Overrides (always false for safety)
    this.devUnlimitedCoins = false,
    this.devUnlockAllLevels = false,
    this.devUnlimitedBoosters = false,
    this.devFastAnimations = false,
  });

  /// Safe production config. Dev overrides are always off.
  static const GameBalanceConfig production = GameBalanceConfig();

  /// Development config with convenient overrides for testing.
  /// NEVER use in release builds — guarded by DataEnvironment.
  static const GameBalanceConfig development = GameBalanceConfig(
    devUnlimitedCoins: true,
    devUnlockAllLevels: true,
    devUnlimitedBoosters: true,
    devFastAnimations: true,
  );

  GameBalanceConfig copyWith({
    int? baseScorePerBlock,
    double? comboMultiplierStep,
    int? maxComboMultiplier,
    int? scorePerStar,
    int? minMatchLength,
    int? bigMatchThreshold,
    int? largeMatchThreshold,
    int? blastMinBlocks,
    int? comboWindowMs,
    int? comboLevel2Threshold,
    int? comboLevel3Threshold,
    int? star1ScorePercent,
    int? star2ScorePercent,
    int? star3ScorePercent,
    int? dailyChallengeCompletionCoins,
    int? levelFirstStarCoins,
    int? levelThreeStarBonusCoins,
    int? achievementBaseCoins,
    int? hammerCoinCost,
    int? shuffleCoinCost,
    int? rowClearCoinCost,
    int? colorClearCoinCost,
    int? extraMovesCoinCost,
    int? extraMovesGranted,
    double? specialBlockSpawnChance,
    int? maxColorsOnBoard,
    bool? devUnlimitedCoins,
    bool? devUnlockAllLevels,
    bool? devUnlimitedBoosters,
    bool? devFastAnimations,
  }) {
    return GameBalanceConfig(
      baseScorePerBlock: baseScorePerBlock ?? this.baseScorePerBlock,
      comboMultiplierStep: comboMultiplierStep ?? this.comboMultiplierStep,
      maxComboMultiplier: maxComboMultiplier ?? this.maxComboMultiplier,
      scorePerStar: scorePerStar ?? this.scorePerStar,
      minMatchLength: minMatchLength ?? this.minMatchLength,
      bigMatchThreshold: bigMatchThreshold ?? this.bigMatchThreshold,
      largeMatchThreshold: largeMatchThreshold ?? this.largeMatchThreshold,
      blastMinBlocks: blastMinBlocks ?? this.blastMinBlocks,
      comboWindowMs: comboWindowMs ?? this.comboWindowMs,
      comboLevel2Threshold: comboLevel2Threshold ?? this.comboLevel2Threshold,
      comboLevel3Threshold: comboLevel3Threshold ?? this.comboLevel3Threshold,
      star1ScorePercent: star1ScorePercent ?? this.star1ScorePercent,
      star2ScorePercent: star2ScorePercent ?? this.star2ScorePercent,
      star3ScorePercent: star3ScorePercent ?? this.star3ScorePercent,
      dailyChallengeCompletionCoins: dailyChallengeCompletionCoins ?? this.dailyChallengeCompletionCoins,
      levelFirstStarCoins: levelFirstStarCoins ?? this.levelFirstStarCoins,
      levelThreeStarBonusCoins: levelThreeStarBonusCoins ?? this.levelThreeStarBonusCoins,
      achievementBaseCoins: achievementBaseCoins ?? this.achievementBaseCoins,
      hammerCoinCost: hammerCoinCost ?? this.hammerCoinCost,
      shuffleCoinCost: shuffleCoinCost ?? this.shuffleCoinCost,
      rowClearCoinCost: rowClearCoinCost ?? this.rowClearCoinCost,
      colorClearCoinCost: colorClearCoinCost ?? this.colorClearCoinCost,
      extraMovesCoinCost: extraMovesCoinCost ?? this.extraMovesCoinCost,
      extraMovesGranted: extraMovesGranted ?? this.extraMovesGranted,
      specialBlockSpawnChance: specialBlockSpawnChance ?? this.specialBlockSpawnChance,
      maxColorsOnBoard: maxColorsOnBoard ?? this.maxColorsOnBoard,
      devUnlimitedCoins: devUnlimitedCoins ?? this.devUnlimitedCoins,
      devUnlockAllLevels: devUnlockAllLevels ?? this.devUnlockAllLevels,
      devUnlimitedBoosters: devUnlimitedBoosters ?? this.devUnlimitedBoosters,
      devFastAnimations: devFastAnimations ?? this.devFastAnimations,
    );
  }
}
