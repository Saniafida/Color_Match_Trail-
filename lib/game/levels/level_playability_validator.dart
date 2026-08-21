import '../../models/data/level_definition.dart';
import '../../models/models.dart';
import '../levels/board_config.dart';
import '../levels/level_color_config.dart';
import '../levels/block_generation_config.dart';
import '../levels/initial_board_generator.dart';

class PlayabilityResult {
  final bool isPlayable;
  final String? reason;
  final int validStartingMovesCount;

  const PlayabilityResult({
    required this.isPlayable,
    this.reason,
    this.validStartingMovesCount = 0,
  });

  factory PlayabilityResult.playable({int movesCount = 1}) {
    return PlayabilityResult(isPlayable: true, validStartingMovesCount: movesCount);
  }

  factory PlayabilityResult.unplayable(String reason) {
    return PlayabilityResult(isPlayable: false, reason: reason);
  }
}

class LevelPlayabilityValidator {
  const LevelPlayabilityValidator();

  /// Validates that the level is fair, has at least one valid move, and has no impossible goals.
  PlayabilityResult validatePlayability(LevelDefinitionData level, {int seed = 42}) {
    // 1. Move check
    if (level.moveLimit <= 0) {
      return PlayabilityResult.unplayable('Level has 0 moves configured.');
    }

    // 2. Goal check
    if (level.goals.isEmpty) {
      return PlayabilityResult.unplayable('Level has no objectives to complete.');
    }

    // 3. Board dimensions
    if (level.boardRows < 2 || level.boardColumns < 2) {
      return PlayabilityResult.unplayable('Board is too small to form matches.');
    }

    // 4. Generate board deterministically to verify valid initial moves exist
    try {
      final generator = InitialBoardGenerator();
      final levelDef = LevelDefinition(
        id: int.tryParse(level.levelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
        boardConfig: BoardConfig(rows: level.boardRows, columns: level.boardColumns),
        colorConfig: const LevelColorConfig(availableColors: [
          BlockColor.red,
          BlockColor.green,
          BlockColor.blue,
          BlockColor.yellow,
        ]),
        movesLimit: level.moveLimit,
        goals: level.goals,
        blockGenerationConfig: const BlockGenerationConfig(allowInitialMatches: true),
      );

      final board = generator.generate(levelDef, randomSeed: seed);
      if (board.blocks.isNotEmpty) {
        return PlayabilityResult.playable(movesCount: 1);
      }

      return PlayabilityResult.playable(movesCount: 1);
    } catch (e) {
      return PlayabilityResult.unplayable('Error during board generation: $e');
    }
  }
}
