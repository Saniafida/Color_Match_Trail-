import 'position.dart';
import 'block.dart';

class BoardCell {
  final Position position;
  final String? blockId; // null if empty

  const BoardCell({
    required this.position,
    this.blockId,
  });

  BoardCell copyWith({
    Position? position,
    String? blockId,
    bool clearBlock = false,
  }) {
    return BoardCell(
      position: position ?? this.position,
      blockId: clearBlock ? null : (blockId ?? this.blockId),
    );
  }
  
  bool get isOccupied => blockId != null;
}

class Board {
  final int rows;
  final int columns;
  final List<BoardCell> cells;
  final Map<String, Block> blocks;

  const Board({
    required this.rows,
    required this.columns,
    this.cells = const [],
    this.blocks = const {},
  }) : assert(rows > 0, 'rows must be positive'),
       assert(columns > 0, 'columns must be positive');

  Board copyWith({
    int? rows,
    int? columns,
    List<BoardCell>? cells,
    Map<String, Block>? blocks,
  }) {
    return Board(
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      cells: cells ?? this.cells,
      blocks: blocks ?? this.blocks,
    );
  }
}
