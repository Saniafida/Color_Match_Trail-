import 'dart:math';
import '../../models/board.dart';
import '../../models/block.dart';
import '../../models/level.dart';
import '../../models/position.dart';
import 'board_validity_checker.dart';

class InitialBoardGenerator {
  final BoardValidityChecker _validator = BoardValidityChecker();

  Board generate(LevelDefinition config, {int? randomSeed}) {
    final rows = config.boardConfig.rows;
    final columns = config.boardConfig.columns;
    final allowedColors = config.colorConfig?.availableColors ?? [];
    
    if (allowedColors.isEmpty) {
      throw StateError('Cannot generate board: No colors configured.');
    }

    final allowInitialMatches = config.blockGenerationConfig?.allowInitialMatches ?? false;
    final allowEmptyCells = config.blockGenerationConfig?.allowEmptyCells ?? false;
    
    int attempts = 0;
    const maxAttempts = 100;
    
    while (attempts < maxAttempts) {
      final board = _attemptGeneration(
        rows: rows,
        columns: columns,
        allowedColors: allowedColors,
        seed: randomSeed != null ? randomSeed + attempts : null,
        allowEmptyCells: allowEmptyCells,
      );

      if (allowInitialMatches || !_hasMatches(board, rows, columns)) {
        if (_validator.validate(board, config)) {
          return board;
        }
      }
      
      attempts++;
    }

    throw StateError('Failed to generate a valid board after $maxAttempts attempts.');
  }

  Board _attemptGeneration({
    required int rows,
    required int columns,
    required List<BlockColor> allowedColors,
    int? seed,
    required bool allowEmptyCells,
  }) {
    final random = seed != null ? Random(seed) : Random();
    final List<BoardCell> cells = [];
    final Map<String, Block> blocks = {};
    int idCounter = 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final position = Position(r, c);
        
        if (allowEmptyCells && random.nextDouble() < 0.1) {
           cells.add(BoardCell(position: position));
           continue;
        }

        final colorIndex = random.nextInt(allowedColors.length);
        final color = allowedColors[colorIndex];
        final blockId = 'block_${r}_${c}_$idCounter';
        idCounter++;

        final block = Block(
          id: blockId,
          color: color,
          position: position,
        );

        blocks[blockId] = block;
        cells.add(BoardCell(position: position, blockId: blockId));
      }
    }

    return Board(rows: rows, columns: columns, cells: cells, blocks: blocks);
  }

  bool _hasMatches(Board board, int rows, int columns) {
    // Quick check for horizontal and vertical matches (3 or more same color)
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final currentBlockId = _getBlockIdAt(board, r, c);
        if (currentBlockId == null) continue;
        final currentColor = board.blocks[currentBlockId]?.color;
        if (currentColor == null) continue;

        // Check horizontal
        if (c <= columns - 3) {
          final id2 = _getBlockIdAt(board, r, c + 1);
          final id3 = _getBlockIdAt(board, r, c + 2);
          if (id2 != null && id3 != null) {
            if (board.blocks[id2]?.color == currentColor && board.blocks[id3]?.color == currentColor) {
              return true;
            }
          }
        }

        // Check vertical
        if (r <= rows - 3) {
          final id2 = _getBlockIdAt(board, r + 1, c);
          final id3 = _getBlockIdAt(board, r + 2, c);
          if (id2 != null && id3 != null) {
            if (board.blocks[id2]?.color == currentColor && board.blocks[id3]?.color == currentColor) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  String? _getBlockIdAt(Board board, int row, int col) {
    try {
      final cell = board.cells.firstWhere((c) => c.position.row == row && c.position.column == col);
      return cell.blockId;
    } catch (_) {
      return null;
    }
  }
}
