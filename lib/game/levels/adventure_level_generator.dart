import 'dart:math';
import '../../models/block.dart';
import '../../models/booster.dart';
import '../../models/goal.dart';
import '../../models/level.dart';
import '../../models/level_rules.dart';
import '../../models/world_definition.dart';
import '../../models/data/level_definition.dart';
import 'board_config.dart';
import 'level_color_config.dart';
import 'spawn_config.dart';
import 'special_level_config.dart';
import 'booster_level_config.dart';
import 'difficulty_config.dart';
import 'block_generation_config.dart';

/// World Theme metadata configuration
class WorldTheme {
  final String title;
  final String description;
  final List<BlockColor> preferredColors;
  final String bgAsset;

  const WorldTheme({
    required this.title,
    required this.description,
    required this.preferredColors,
    required this.bgAsset,
  });
}

/// High quality deterministic procedural level generator for Color Match Trail.
/// Generates full LevelDefinition and LevelDefinitionData for Levels 1 to 147+.
class AdventureLevelGenerator {
  static const int totalAdventureLevels = 147;

  static const List<WorldTheme> worldThemes = [
    WorldTheme(
      title: 'Color Meadows',
      description: 'Begin your journey across vibrant fields of flowers and color.',
      preferredColors: [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.yellow],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Prism Valley',
      description: 'Master advanced color trails through glowing crystal valleys.',
      preferredColors: [BlockColor.purple, BlockColor.blue, BlockColor.green, BlockColor.yellow, BlockColor.red],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Crystal Caves',
      description: 'Explore subterranean caverns illuminated by radiant gems.',
      preferredColors: [BlockColor.purple, BlockColor.blue, BlockColor.orange, BlockColor.yellow],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Sunset Shores',
      description: 'Relax by golden waters while creating massive explosive blasts.',
      preferredColors: [BlockColor.orange, BlockColor.red, BlockColor.yellow, BlockColor.purple],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Mystic Forest',
      description: 'Uncover ancient enchanted groves and magical matching trails.',
      preferredColors: [BlockColor.green, BlockColor.purple, BlockColor.blue, BlockColor.yellow, BlockColor.orange],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Starlight Peaks',
      description: 'Climb majestic mountains under twinkling celestial constellations.',
      preferredColors: [BlockColor.blue, BlockColor.purple, BlockColor.yellow, BlockColor.red, BlockColor.green],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Golden Desert',
      description: 'Journey through dunes of ancient relics, warm sands and sunshine.',
      preferredColors: [BlockColor.yellow, BlockColor.orange, BlockColor.red, BlockColor.purple],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Emerald Jungle',
      description: 'Navigate dense lush foliage, exotic vines and tropical blooms.',
      preferredColors: [BlockColor.green, BlockColor.yellow, BlockColor.orange, BlockColor.blue, BlockColor.red],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Coral Reef',
      description: 'Dive into crystal blue oceans teeming with vivid aquatic life.',
      preferredColors: [BlockColor.blue, BlockColor.orange, BlockColor.green, BlockColor.purple, BlockColor.yellow],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Aurora Tundra',
      description: 'Witness the celestial northern lights across icy glacial plains.',
      preferredColors: [BlockColor.blue, BlockColor.purple, BlockColor.green, BlockColor.yellow],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Volcano Ridge',
      description: 'Tame molten peaks with explosive fiery power-ups and mega combos.',
      preferredColors: [BlockColor.red, BlockColor.orange, BlockColor.yellow, BlockColor.purple],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Sky Citadel',
      description: 'Soar among floating mythical islands high in the cloud kingdom.',
      preferredColors: [BlockColor.blue, BlockColor.yellow, BlockColor.purple, BlockColor.green, BlockColor.orange],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Cosmic Nebula',
      description: 'Travel through stellar clouds and shimmering star dust corridors.',
      preferredColors: [BlockColor.purple, BlockColor.blue, BlockColor.red, BlockColor.yellow, BlockColor.green, BlockColor.orange],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Enchanted Realm',
      description: 'Harness legendary magic power in the wizard master sanctuary.',
      preferredColors: [BlockColor.purple, BlockColor.green, BlockColor.blue, BlockColor.orange, BlockColor.yellow, BlockColor.red],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
    WorldTheme(
      title: 'Grand Adventure',
      description: 'Claim the championship golden trophy in the ultimate final trials.',
      preferredColors: [BlockColor.yellow, BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.purple, BlockColor.orange],
      bgAsset: 'assets/images/backgrounds/bg_garden.jpg',
    ),
  ];

  /// Generates a rich, balanced LevelDefinition for gameplay.
  static LevelDefinition generateLevel(int levelNumber) {
    final seed = levelNumber * 1000 + 77;
    final random = Random(seed);

    final worldIndex = ((levelNumber - 1) ~/ 10).clamp(0, worldThemes.length - 1);
    final theme = worldThemes[worldIndex];

    // 1. Board Dimensions (6x6 for early, 7x7 for mid, 8x8 for advanced)
    int rows = 6;
    int cols = 6;
    if (levelNumber >= 25) {
      rows = 8;
      cols = 8;
    } else if (levelNumber >= 6) {
      rows = 7;
      cols = 7;
    }

    // 2. Available Colors based on World theme & progression
    final List<BlockColor> allColors = [
      BlockColor.red,
      BlockColor.blue,
      BlockColor.green,
      BlockColor.yellow,
      BlockColor.purple,
      BlockColor.orange,
    ];

    List<BlockColor> availableColors;
    if (levelNumber <= 4) {
      availableColors = [BlockColor.red, BlockColor.blue, BlockColor.green, BlockColor.yellow];
    } else if (levelNumber <= 15) {
      availableColors = List.from(theme.preferredColors.take(5));
      if (availableColors.length < 5) {
        for (final c in allColors) {
          if (!availableColors.contains(c)) availableColors.add(c);
          if (availableColors.length >= 5) break;
        }
      }
    } else {
      availableColors = List.from(allColors);
    }

    // 3. Difficulty Tier
    final isBossLevel = levelNumber % 10 == 0 || levelNumber == totalAdventureLevels;
    final isHardLevel = !isBossLevel && levelNumber % 5 == 0;

    // 4. Determine Dynamic Level Goal Archetype to guarantee variety
    // Archetypes:
    // 0: Dual Color Rush
    // 1: Primary Color + Special Creator (Rockets / Bombs)
    // 2: Triple Color Clearance (for higher levels) or Color + Score Target
    // 3: Color + Cascade Combo Goal
    // 4: Boss Trial (3 epic goals: 2 colors + 1 powerup creation)
    final archetypeIndex = isBossLevel ? 4 : (levelNumber % 4);

    final List<GoalDefinition> goals = [];
    final shuffledColors = List<BlockColor>.from(availableColors)..shuffle(random);
    final color1 = shuffledColors[0];
    final color2 = shuffledColors.length > 1 ? shuffledColors[1] : BlockColor.blue;
    final color3 = shuffledColors.length > 2 ? shuffledColors[2] : BlockColor.green;

    // Target counts scaling smoothly with level
    final int baseCount = 14 + (levelNumber * 0.18).floor() * 2;
    final int primaryTarget = (baseCount + (isBossLevel ? 10 : (isHardLevel ? 6 : 0))).clamp(14, 45);
    final int secondaryTarget = (baseCount - 2 + (isBossLevel ? 8 : (isHardLevel ? 4 : 0))).clamp(12, 38);

    if (archetypeIndex == 0) {
      // Archetype 0: Dual Color Clear
      goals.add(GoalDefinition(
        id: 'goal_1',
        type: GoalType.clearColor,
        targetAmount: primaryTarget,
        color: color1,
      ));
      if (levelNumber > 1) {
        goals.add(GoalDefinition(
          id: 'goal_2',
          type: GoalType.clearColor,
          targetAmount: secondaryTarget,
          color: color2,
        ));
      }
    } else if (archetypeIndex == 1) {
      // Archetype 1: Clear Color + Create Power-Ups
      goals.add(GoalDefinition(
        id: 'goal_1',
        type: GoalType.clearColor,
        targetAmount: primaryTarget,
        color: color1,
      ));
      final specialTarget = (2 + (levelNumber ~/ 30)).clamp(2, 6);
      goals.add(GoalDefinition(
        id: 'goal_2',
        type: GoalType.createSpecial,
        targetAmount: specialTarget,
        specialType: (levelNumber % 2 == 0) ? SpecialBlockType.bomb : SpecialBlockType.verticalLine,
      ));
    } else if (archetypeIndex == 2) {
      // Archetype 2: Triple Color (if available) or Color + Score Target
      goals.add(GoalDefinition(
        id: 'goal_1',
        type: GoalType.clearColor,
        targetAmount: primaryTarget,
        color: color1,
      ));
      goals.add(GoalDefinition(
        id: 'goal_2',
        type: GoalType.clearColor,
        targetAmount: secondaryTarget,
        color: color2,
      ));
      if (levelNumber >= 15) {
        final tertiaryTarget = (secondaryTarget - 4).clamp(10, 28);
        goals.add(GoalDefinition(
          id: 'goal_3',
          type: GoalType.clearColor,
          targetAmount: tertiaryTarget,
          color: color3,
        ));
      }
    } else if (archetypeIndex == 3) {
      // Archetype 3: Color + Cascade Combo Goal
      goals.add(GoalDefinition(
        id: 'goal_1',
        type: GoalType.clearColor,
        targetAmount: primaryTarget,
        color: color1,
      ));
      final cascadeLevelTarget = (2 + (levelNumber ~/ 40)).clamp(2, 4);
      goals.add(GoalDefinition(
        id: 'goal_2',
        type: GoalType.reachCascade,
        targetAmount: cascadeLevelTarget,
      ));
    } else {
      // Archetype 4: Boss Level (3 Epic Goals)
      goals.add(GoalDefinition(
        id: 'goal_1',
        type: GoalType.clearColor,
        targetAmount: primaryTarget + 5,
        color: color1,
      ));
      goals.add(GoalDefinition(
        id: 'goal_2',
        type: GoalType.clearColor,
        targetAmount: secondaryTarget + 4,
        color: color2,
      ));
      goals.add(GoalDefinition(
        id: 'goal_3',
        type: GoalType.createSpecial,
        targetAmount: 3 + (levelNumber ~/ 40),
        specialType: SpecialBlockType.bomb,
      ));
    }

    // 5. Move Limit Calculation tailored to goals
    int moves = 24;
    int totalGoalPoints = goals.fold(0, (sum, g) => sum + (g.type == GoalType.createSpecial ? g.targetAmount * 4 : g.targetAmount));
    if (isBossLevel) {
      moves = 34 + (levelNumber ~/ 25) * 2;
    } else if (isHardLevel) {
      moves = 28 + (levelNumber ~/ 30);
    } else {
      moves = (totalGoalPoints * 0.55).round().clamp(22, 36);
    }
    moves = moves.clamp(20, 44);

    // 6. Specials & Boosters
    final allowedSpecials = <SpecialBlockType>[
      SpecialBlockType.horizontalLine,
      SpecialBlockType.verticalLine,
      SpecialBlockType.bomb,
      SpecialBlockType.colorSpecial,
      SpecialBlockType.crossBlast,
      SpecialBlockType.smallArea,
      SpecialBlockType.megaBomb,
    ];

    final allowedBoosters = <BoosterType>[
      BoosterType.hammer,
      BoosterType.shuffle,
      BoosterType.rowClear,
      BoosterType.colorClear,
      BoosterType.areaBlast,
      BoosterType.extraMoves,
    ];

    return LevelDefinition(
      id: levelNumber,
      version: 1,
      boardConfig: BoardConfig(rows: rows, columns: cols),
      movesLimit: moves,
      winRule: WinRule.allRequiredGoalsCompleted,
      loseRule: LoseRule.movesOrTimeExhausted,
      goals: goals,
      colorConfig: LevelColorConfig(availableColors: availableColors),
      spawnConfig: const SpawnConfig(avoidImmediateMatch: true),
      specialConfig: SpecialLevelConfig(
        enabled: true,
        allowedSpecialTypes: allowedSpecials,
      ),
      boosterConfig: BoosterLevelConfig(
        allowedBoosters: allowedBoosters,
      ),
      difficultyConfig: DifficultyConfig(
        colorCount: availableColors.length,
        spawnDifficulty: isBossLevel ? 0.8 : (isHardLevel ? 0.6 : 0.4),
      ),
      blockGenerationConfig: const BlockGenerationConfig(
        allowInitialMatches: false,
        allowEmptyCells: false,
      ),
    );
  }

  /// Generates offline data model LevelDefinitionData.
  static LevelDefinitionData generateData(int levelNumber) {
    final def = generateLevel(levelNumber);
    final isBoss = levelNumber % 10 == 0 || levelNumber == totalAdventureLevels;
    final isHard = !isBoss && levelNumber % 5 == 0;

    final baseScore = (levelNumber * 500) + 1200;
    final star1 = (baseScore * 0.5).round();
    final star2 = (baseScore * 0.75).round();
    final star3 = baseScore;

    final worldIndex = ((levelNumber - 1) ~/ 10) + 1;

    return LevelDefinitionData(
      levelId: 'level_$levelNumber',
      worldId: 'world_$worldIndex',
      boardRows: def.boardConfig.rows,
      boardColumns: def.boardConfig.columns,
      blockTypes: const ['normal'],
      goals: def.goals,
      moveLimit: def.movesLimit ?? 25,
      availableBoosters: const [
        BoosterType.hammer,
        BoosterType.shuffle,
        BoosterType.rowClear,
        BoosterType.colorClear,
        BoosterType.areaBlast,
        BoosterType.extraMoves,
      ],
      difficulty: isBoss ? 'expert' : (isHard ? 'hard' : (levelNumber <= 4 ? 'easy' : 'normal')),
      scoreTarget: star3,
      starThresholds: [star1, star2, star3],
    );
  }

  /// Generates the campaign worlds encompassing all 147 levels.
  static List<WorldDefinition> generateAllWorlds() {
    final List<WorldDefinition> worlds = [];
    int currentLevel = 1;

    for (int i = 0; i < worldThemes.length; i++) {
      final theme = worldThemes[i];
      final worldNum = i + 1;
      final worldId = 'world_$worldNum';

      final levelIds = <String>[];
      final levelsInThisWorld = (worldNum == worldThemes.length) ? (totalAdventureLevels - currentLevel + 1) : 10;

      for (int l = 0; l < levelsInThisWorld && currentLevel <= totalAdventureLevels; l++) {
        levelIds.add('level_$currentLevel');
        currentLevel++;
      }

      if (levelIds.isEmpty) break;

      final unlockReq = (worldNum == 1) ? 0 : (worldNum - 1) * 10;

      worlds.add(WorldDefinition(
        worldId: worldId,
        titleKey: theme.title,
        descriptionKey: theme.description,
        levelIds: levelIds,
        firstLevelId: levelIds.first,
        lastLevelId: levelIds.last,
        unlockRequirement: unlockReq,
        requiredLevelId: worldNum > 1 ? 'level_${(worldNum - 1) * 10}' : null,
        rewardCoins: 100 + (worldNum * 50),
        mapAsset: theme.bgAsset,
        backgroundAsset: theme.bgAsset,
        enabled: true,
      ));
    }

    return worlds;
  }
}
