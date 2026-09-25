import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/blocks/block_factory.dart';
import 'package:color_match_trail/game/board/board.dart' hide BoardConfig;
import 'package:color_match_trail/game/goals/goal_controller.dart';
import 'package:color_match_trail/game/gravity/gravity_controller.dart';
import 'package:color_match_trail/game/levels/initial_board_generator.dart';
import 'package:color_match_trail/game/levels/board_config.dart';
import 'package:color_match_trail/game/levels/level_color_config.dart';
import 'package:color_match_trail/game/levels/adventure_level_generator.dart';
import 'package:color_match_trail/game/blast/blast_result.dart';

void main() {
  group('Target Block Spawn Bias Tests', () {
    test('BlockFactory.getRandomColor produces target colors with high frequency (~60%+)', () {
      final allowedColors = [
        BlockColor.red,
        BlockColor.blue,
        BlockColor.green,
        BlockColor.yellow,
        BlockColor.purple,
      ];
      final targetColors = [BlockColor.red];
      final rng = Random(42);

      int targetCount = 0;
      const iterations = 1000;

      for (int i = 0; i < iterations; i++) {
        final color = BlockFactory.getRandomColor(
          allowedColors,
          targetColors: targetColors,
          targetBias: 0.60,
          rng: rng,
        );
        if (targetColors.contains(color)) {
          targetCount++;
        }
      }

      // Without bias, Red would appear ~20% (200 times).
      // With 60% bias, Red should appear around 60% + (0.40 * 0.20 = 8%) = ~68% (> 600 times).
      final frequency = targetCount / iterations;
      expect(frequency, greaterThan(0.60));
    });

    test('InitialBoardGenerator generates board rich in target colors when goals are present', () {
      final generator = InitialBoardGenerator();
      final level = LevelDefinition(
        id: 1,
        boardConfig: const BoardConfig(rows: 6, columns: 6),
        colorConfig: const LevelColorConfig(
          availableColors: [
            BlockColor.red,
            BlockColor.blue,
            BlockColor.green,
            BlockColor.yellow,
            BlockColor.purple,
          ],
        ),
        goals: const [
          GoalDefinition(
            id: 'goal_1',
            type: GoalType.clearColor,
            targetAmount: 15,
            color: BlockColor.red,
          ),
        ],
      );

      final board = generator.generate(level, randomSeed: 100);
      int redCount = 0;
      for (final cell in board.cells) {
        final block = board.blocks[cell.blockId];
        if (block?.color == BlockColor.red) {
          redCount++;
        }
      }

      // In a 36-cell board with 5 colors, uniform random would give ~7 Red blocks.
      // With target bias, Red blocks should be significantly higher (> 14 out of 36, ~40-60%+).
      expect(redCount, greaterThanOrEqualTo(14));
    });

    test('GoalController tracks allTargetColors and dynamically adjusts activeTargetColors', () {
      final controller = GoalController();
      controller.initialize(const [
        GoalDefinition(
          id: 'goal_red',
          type: GoalType.clearColor,
          targetAmount: 10,
          color: BlockColor.red,
        ),
        GoalDefinition(
          id: 'goal_blue',
          type: GoalType.clearColor,
          targetAmount: 10,
          color: BlockColor.blue,
        ),
      ]);

      // Both Red and Blue are targets initially
      expect(controller.allTargetColors, containsAll([BlockColor.red, BlockColor.blue]));
      expect(controller.activeTargetColors, containsAll([BlockColor.red, BlockColor.blue]));

      // Complete Red goal
      controller.onBlastResult(const BlastResult(
        destroyedPositions: [],
        destroyedBlockIds: [],
        color: BlockColor.red,
        destroyedCount: 10,
        source: DestructionSource.playerMatch,
        intensity: BlastIntensity.normal,
        success: true,
      ));

      // Now Red is completed, so activeTargetColors should only have Blue
      expect(controller.activeTargetColors, equals([BlockColor.blue]));
      expect(controller.allTargetColors, containsAll([BlockColor.red, BlockColor.blue]));
    });

    test('GravityController spawns new blocks with targetColors bias during refill', () async {
      final boardController = BoardController(rows: 4, columns: 4);
      final blocks = <String, Block>{};

      final gravityController = GravityController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (b) => blocks[b.id] = b,
        onCreateBlock: (b) => blocks[b.id] = b,
      );

      // Leave entire top 2 rows empty
      for (int c = 0; c < 4; c++) {
        final b1 = Block(id: 'b_2_$c', color: BlockColor.green, position: Position(2, c));
        final b2 = Block(id: 'b_3_$c', color: BlockColor.green, position: Position(3, c));
        blocks[b1.id] = b1;
        blocks[b2.id] = b2;
        boardController.setBlockId(Position(2, c), b1.id);
        boardController.setBlockId(Position(3, c), b2.id);
      }

      final allowedColors = [
        BlockColor.red,
        BlockColor.blue,
        BlockColor.green,
        BlockColor.yellow,
        BlockColor.purple,
      ];
      final targetColors = [BlockColor.yellow];

      // Refill 8 empty cells with 90% bias towards yellow for statistical certainty
      final result = await gravityController.applyGravity(
        allowedColors,
        targetColors: targetColors,
        targetBias: 0.90,
      );

      expect(result.spawnedBlocks.length, equals(8));
      final yellowCount = result.spawnedBlocks.where((b) => b.color == BlockColor.yellow).length;
      expect(yellowCount, greaterThanOrEqualTo(5)); // Out of 8, vast majority are yellow
    });

    test('Rocket blast with mixed colors credits all destroyed block colors to their respective goals', () {
      final goalController = GoalController();
      goalController.initialize(const [
        GoalDefinition(
          id: 'goal_blue',
          type: GoalType.clearColor,
          targetAmount: 10,
          color: BlockColor.blue,
        ),
        GoalDefinition(
          id: 'goal_yellow',
          type: GoalType.clearColor,
          targetAmount: 10,
          color: BlockColor.yellow,
        ),
        GoalDefinition(
          id: 'goal_red',
          type: GoalType.clearColor,
          targetAmount: 10,
          color: BlockColor.red,
        ),
      ]);

      // Rocket was originally made of Red color, but in its row blast it destroyed:
      // 1 Red block, 3 Blue blocks, and 2 Yellow blocks (total 6 blocks)
      final rocketBlastResult = const BlastResult(
        success: true,
        destroyedCount: 6,
        color: BlockColor.red,
        destroyedColorCounts: {
          BlockColor.red: 1,
          BlockColor.blue: 3,
          BlockColor.yellow: 2,
        },
        source: DestructionSource.special,
      );

      goalController.onBlastResult(rocketBlastResult);

      final blueState = goalController.states.firstWhere((s) => s.goalId == 'goal_blue');
      final yellowState = goalController.states.firstWhere((s) => s.goalId == 'goal_yellow');
      final redState = goalController.states.firstWhere((s) => s.goalId == 'goal_red');

      // Blue must have received +3
      expect(blueState.currentAmount, equals(3));
      // Yellow must have received +2
      expect(yellowState.currentAmount, equals(2));
      // Red must have received +1 (NOT 6!)
      expect(redState.currentAmount, equals(1));
    });

    test('Level 11 goals replace reachCascade with intuitive power-up goal', () {
      final level11 = AdventureLevelGenerator.generateLevel(11);
      
      // Must not contain reachCascade
      final hasCascade = level11.goals.any((g) => g.type == GoalType.reachCascade);
      expect(hasCascade, isFalse);

      // Must have clearColor purple and createSpecial rocket
      final purpleGoal = level11.goals.firstWhere((g) => g.type == GoalType.clearColor);
      expect(purpleGoal.color, equals(BlockColor.purple));
      expect(purpleGoal.targetAmount, equals(16));

      final specialGoal = level11.goals.firstWhere((g) => g.type == GoalType.createSpecial);
      expect(specialGoal.specialType, equals(SpecialBlockType.horizontalLine));
      expect(specialGoal.targetAmount, equals(2));
    });
  });
}
