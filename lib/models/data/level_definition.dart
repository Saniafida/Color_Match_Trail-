import '../booster.dart';
import '../goal.dart';
import '../block.dart';

/// Flatter, offline-data-driven LevelDefinition as requested for Module 46.
class LevelDefinitionData {
  final String levelId;
  final String worldId;
  final int boardRows;
  final int boardColumns;
  final List<String> blockTypes; // e.g., 'normal', 'locked'
  final List<Map<String, dynamic>> initialBlocks; // Config for starting grid
  final List<GoalDefinition> goals;
  final int moveLimit;
  final List<BoosterType> availableBoosters;
  final String difficulty; // 'easy', 'normal', 'hard', 'expert'
  final int scoreTarget;
  final List<int> starThresholds;

  const LevelDefinitionData({
    required this.levelId,
    this.worldId = 'world_1',
    required this.boardRows,
    required this.boardColumns,
    this.blockTypes = const ['normal'],
    this.initialBlocks = const [],
    required this.goals,
    required this.moveLimit,
    this.availableBoosters = const [],
    this.difficulty = 'normal',
    this.scoreTarget = 1000,
    this.starThresholds = const [1000, 2000, 3000],
  });

  factory LevelDefinitionData.fromJson(Map<String, dynamic> json) {
    return LevelDefinitionData(
      levelId: json['levelId'] as String? ?? 'level_0',
      worldId: json['worldId'] as String? ?? 'world_1',
      boardRows: json['boardRows'] as int? ?? 6,
      boardColumns: json['boardColumns'] as int? ?? 6,
      blockTypes: (json['blockTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['normal'],
      initialBlocks: (json['initialBlocks'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      goals: (json['goals'] as List<dynamic>?)?.map((e) => _parseGoal(e as Map<String, dynamic>)).toList() ?? [],
      moveLimit: json['moveLimit'] as int? ?? 20,
      availableBoosters: (json['availableBoosters'] as List<dynamic>?)?.map((e) {
        return BoosterType.values.firstWhere((b) => b.name == e.toString(), orElse: () => BoosterType.hammer);
      }).toList() ?? BoosterType.values,
      difficulty: json['difficulty'] as String? ?? 'normal',
      scoreTarget: json['scoreTarget'] as int? ?? 1000,
      starThresholds: (json['starThresholds'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [1000, 2000, 3000],
    );
  }

  static GoalDefinition _parseGoal(Map<String, dynamic> json) {
    return GoalDefinition(
      id: json['id'] as String? ?? 'goal',
      type: GoalType.values.firstWhere((e) => e.name == json['type'], orElse: () => GoalType.clearColor),
      targetAmount: json['targetAmount'] as int? ?? json['target'] as int? ?? 1,
      color: json['color'] != null
          ? BlockColor.values.firstWhere((e) => e.name == json['color'], orElse: () => BlockColor.red)
          : null,
    );
  }
}
