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

/// High quality deterministic procedural level generator for Color Match Trail.
/// Generates full LevelDefinition and LevelDefinitionData for Levels 1 to 147+.
class AdventureLevelGenerator {
  static const int totalAdventureLevels = 147;

  /// Generates a rich, balanced LevelDefinition for gameplay.
  static LevelDefinition generateLevel(int levelNumber) {
    final seed = levelNumber * 1000 + 42;
    final random = Random(seed);

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

    // 2. Available Colors (4 colors for early, 5 colors for mid, 6 colors for high)
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
      availableColors = [
        BlockColor.red,
        BlockColor.blue,
        BlockColor.green,
        BlockColor.yellow,
        BlockColor.purple,
      ];
    } else {
      availableColors = List.from(allColors);
    }

    // 3. Difficulty Tier
    final isBossLevel = levelNumber % 10 == 0;
    final isHardLevel = levelNumber % 5 == 0;

    // 4. Move Limit
    int moves = 25;
    if (isBossLevel) {
      moves = 35 + (levelNumber ~/ 30) * 2;
    } else if (isHardLevel) {
      moves = 30 + (levelNumber ~/ 30);
    } else {
      moves = 24 + ((levelNumber * 3) % 7);
    }
    moves = moves.clamp(20, 42);

    // 5. Goals
    final List<GoalDefinition> goals = [];
    final availableColorPool = List<BlockColor>.from(availableColors)..shuffle(random);

    // Primary Goal: Clear Color 1
    final primaryColor = availableColorPool[0];
    final int primaryTarget = (15 + (levelNumber * 0.22).floor() * 2 + (isBossLevel ? 10 : 0)).clamp(15, 45);
    goals.add(GoalDefinition(
      id: 'goal_1',
      type: GoalType.clearColor,
      targetAmount: primaryTarget,
      color: primaryColor,
    ));

    // Secondary Goal: Clear Color 2 (for levels > 1)
    if (levelNumber >= 2 && availableColorPool.length > 1) {
      final secondaryColor = availableColorPool[1];
      final int secondaryTarget = (12 + (levelNumber * 0.18).floor() * 2 + (isHardLevel ? 6 : 0)).clamp(12, 40);
      goals.add(GoalDefinition(
        id: 'goal_2',
        type: GoalType.clearColor,
        targetAmount: secondaryTarget,
        color: secondaryColor,
      ));
    }

    // Tertiary Goal: For level 20+ on milestone levels
    if (levelNumber >= 20 && (levelNumber % 4 == 0) && availableColorPool.length > 2) {
      final tertiaryColor = availableColorPool[2];
      final int tertiaryTarget = (10 + (levelNumber * 0.12).floor() * 2).clamp(10, 30);
      goals.add(GoalDefinition(
        id: 'goal_3',
        type: GoalType.clearColor,
        targetAmount: tertiaryTarget,
        color: tertiaryColor,
      ));
    }

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
    final isBoss = levelNumber % 10 == 0;
    final isHard = levelNumber % 5 == 0;

    final baseScore = (levelNumber * 450) + 1000;
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
      ],
      difficulty: isBoss ? 'expert' : (isHard ? 'hard' : 'normal'),
      scoreTarget: star3,
      starThresholds: [star1, star2, star3],
    );
  }

  /// Generates the campaign worlds encompassing all 147 levels.
  static List<WorldDefinition> generateAllWorlds() {
    const worldNames = [
      ('Color Meadows', 'Begin your journey across vibrant fields of color.'),
      ('Prism Valley', 'Master advanced color trails through crystalline valleys.'),
      ('Crystal Caves', 'Explore subterranean glowing caverns of gems.'),
      ('Sunset Shores', 'Relax by golden waters while creating huge blasts.'),
      ('Mystic Forest', 'Uncover ancient enchanted groves and magic trails.'),
      ('Starlight Peaks', 'Climb majestic mountains under twinkling constellations.'),
      ('Golden Desert', 'Journey through dunes of buried relics and sunshine.'),
      ('Emerald Jungle', 'Navigate dense lush foliage and tropical blooms.'),
      ('Coral Reef', 'Dive into crystal blue oceans teeming with vivid life.'),
      ('Aurora Tundra', 'Witness the celestial northern lights over icy plains.'),
      ('Volcano Ridge', 'Tame molten peaks with explosive fiery power-ups.'),
      ('Sky Citadel', 'Soar among floating islands high in the cloud kingdom.'),
      ('Cosmic Nebula', 'Travel through stellar clouds and star dust corridors.'),
      ('Enchanted Realm', 'Harness legendary magic power in the wizard realm.'),
      ('Grand Adventure', 'Claim the golden championship trophy in the final trials.'),
    ];

    final List<WorldDefinition> worlds = [];
    int currentLevel = 1;

    for (int i = 0; i < worldNames.length; i++) {
      final (title, desc) = worldNames[i];
      final worldNum = i + 1;
      final worldId = 'world_$worldNum';

      final levelIds = <String>[];
      final levelsInThisWorld = (worldNum == worldNames.length) ? (totalAdventureLevels - currentLevel + 1) : 10;

      for (int l = 0; l < levelsInThisWorld && currentLevel <= totalAdventureLevels; l++) {
        levelIds.add('level_$currentLevel');
        currentLevel++;
      }

      if (levelIds.isEmpty) break;

      final unlockReq = (worldNum == 1) ? 0 : (worldNum - 1) * 12;

      worlds.add(WorldDefinition(
        worldId: worldId,
        titleKey: title,
        descriptionKey: desc,
        levelIds: levelIds,
        firstLevelId: levelIds.first,
        lastLevelId: levelIds.last,
        unlockRequirement: unlockReq,
        rewardCoins: 100 + (worldNum * 50),
        mapAsset: 'assets/images/backgrounds/bg_garden.jpg',
        backgroundAsset: 'assets/images/backgrounds/bg_garden.jpg',
        enabled: true,
      ));
    }

    return worlds;
  }
}
