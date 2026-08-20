import 'block.dart';
import 'goal.dart';
import 'level_rules.dart';
import '../game/levels/board_config.dart';
import '../game/levels/level_color_config.dart';
import '../game/levels/block_generation_config.dart';
import '../game/levels/spawn_config.dart';
import '../game/levels/special_level_config.dart';
import '../game/levels/booster_level_config.dart';
import '../game/levels/difficulty_config.dart';
import 'booster.dart';

enum LevelDifficulty { easy, medium, hard, expert }

class LevelDefinition {
  final int id;
  final int version;
  final BoardConfig boardConfig;
  final int? movesLimit;
  final int? timeLimit;
  final WinRule winRule;
  final LoseRule loseRule;
  final List<GoalDefinition> goals;
  final LevelColorConfig? colorConfig;
  final SpawnConfig? spawnConfig;
  final SpecialLevelConfig? specialConfig;
  final BoosterLevelConfig? boosterConfig;
  final DifficultyConfig? difficultyConfig;
  final BlockGenerationConfig? blockGenerationConfig;

  const LevelDefinition({
    required this.id,
    this.version = 1,
    required this.boardConfig,
    this.movesLimit,
    this.timeLimit,
    this.winRule = WinRule.allRequiredGoalsCompleted,
    this.loseRule = LoseRule.movesOrTimeExhausted,
    this.goals = const [],
    this.colorConfig,
    this.spawnConfig,
    this.specialConfig,
    this.boosterConfig,
    this.difficultyConfig,
    this.blockGenerationConfig,
  });

  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    return LevelDefinition(
      id: json['id'] as int,
      version: json['version'] as int? ?? 1,
      boardConfig: json['board'] != null 
          ? BoardConfig.fromJson(json['board'] as Map<String, dynamic>) 
          : const BoardConfig(rows: 6, columns: 6),
      movesLimit: json['movesLimit'] ?? json['moves'],
      timeLimit: json['timeLimit'],
      winRule: json['winRule'] != null 
          ? WinRule.values.firstWhere((e) => e.name == json['winRule'], orElse: () => WinRule.allRequiredGoalsCompleted)
          : WinRule.allRequiredGoalsCompleted,
      loseRule: json['loseRule'] != null
          ? LoseRule.values.firstWhere((e) => e.name == json['loseRule'], orElse: () => LoseRule.movesOrTimeExhausted)
          : LoseRule.movesOrTimeExhausted,
      goals: (json['goals'] as List<dynamic>?)?.map((e) => _parseGoal(e as Map<String, dynamic>)).toList() ?? [],
      colorConfig: json['colors'] != null 
          ? (json['colors'] is List 
              ? LevelColorConfig(
                  availableColors: (json['colors'] as List).map((c) => BlockColor.values.firstWhere((e) => e.name == c)).toList(),
                )
              : LevelColorConfig.fromJson(json['colors'] as Map<String, dynamic>))
          : null,
      spawnConfig: json['spawn'] != null ? SpawnConfig.fromJson(json['spawn'] as Map<String, dynamic>) : null,
      specialConfig: json['specials'] != null ? SpecialLevelConfig.fromJson(json['specials'] as Map<String, dynamic>) : null,
      boosterConfig: json['boosters'] != null ? BoosterLevelConfig.fromJson(json['boosters'] as Map<String, dynamic>) : null,
      difficultyConfig: json['difficulty'] != null ? DifficultyConfig.fromJson(json['difficulty'] as Map<String, dynamic>) : null,
      blockGenerationConfig: json['generation'] != null ? BlockGenerationConfig.fromJson(json['generation'] as Map<String, dynamic>) : null,
    );
  }

  static GoalDefinition _parseGoal(Map<String, dynamic> json) {
    return GoalDefinition(
      id: json['id'] as String,
      type: GoalType.values.firstWhere((e) => e.name == json['type'], orElse: () => GoalType.clearColor),
      targetAmount: json['target'] as int? ?? json['targetAmount'] as int? ?? 1,
      color: json['color'] != null ? BlockColor.values.firstWhere((e) => e.name == json['color']) : null,
      specialType: json['specialType'] != null ? SpecialBlockType.values.firstWhere((e) => e.name == json['specialType']) : null,
      boosterType: json['boosterType'] != null ? BoosterType.values.firstWhere((e) => e.name == json['boosterType']) : null,
      isOptional: json['optional'] as bool? ?? false,
    );
  }

  LevelDefinition copyWith({
    int? id,
    int? version,
    BoardConfig? boardConfig,
    int? movesLimit,
    int? timeLimit,
    WinRule? winRule,
    LoseRule? loseRule,
    List<GoalDefinition>? goals,
    LevelColorConfig? colorConfig,
    SpawnConfig? spawnConfig,
    SpecialLevelConfig? specialConfig,
    BoosterLevelConfig? boosterConfig,
    DifficultyConfig? difficultyConfig,
    BlockGenerationConfig? blockGenerationConfig,
  }) {
    return LevelDefinition(
      id: id ?? this.id,
      version: version ?? this.version,
      boardConfig: boardConfig ?? this.boardConfig,
      movesLimit: movesLimit ?? this.movesLimit,
      timeLimit: timeLimit ?? this.timeLimit,
      winRule: winRule ?? this.winRule,
      loseRule: loseRule ?? this.loseRule,
      goals: goals ?? this.goals,
      colorConfig: colorConfig ?? this.colorConfig,
      spawnConfig: spawnConfig ?? this.spawnConfig,
      specialConfig: specialConfig ?? this.specialConfig,
      boosterConfig: boosterConfig ?? this.boosterConfig,
      difficultyConfig: difficultyConfig ?? this.difficultyConfig,
      blockGenerationConfig: blockGenerationConfig ?? this.blockGenerationConfig,
    );
  }
}
