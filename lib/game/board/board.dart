import '../../models/models.dart';

/// Board Configuration for setup/layout preferences.
class BoardConfig {
  final int rows;
  final int columns;
  final double cellSpacing;
  final double boardPadding;

  const BoardConfig({
    required this.rows,
    required this.columns,
    this.cellSpacing = 4.0,
    this.boardPadding = 16.0,
  });
}

/// Manages the logical game grid.
class BoardController {
  late Board _board;

  BoardController({required int rows, required int columns}) {
    _initialize(rows, columns);
  }

  void _initialize(int rows, int columns) {
    if (rows <= 0 || columns <= 0) {
      throw ArgumentError('Dimensions must be positive');
    }
    
    final cells = <BoardCell>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        cells.add(BoardCell(position: Position(r, c)));
      }
    }
    
    _board = Board(
      rows: rows,
      columns: columns,
      cells: cells,
      blocks: const {},
    );
  }

  // Access to state
  Board get board => _board;
  int get rows => _board.rows;
  int get columns => _board.columns;

  // Position Validation
  bool isValidPosition(Position position) {
    return position.row >= 0 &&
           position.row < rows &&
           position.column >= 0 &&
           position.column < columns;
  }

  // Index Conversion
  int positionToIndex(Position position) {
    if (!isValidPosition(position)) {
      throw ArgumentError('Invalid position $position for ${rows}x$columns board');
    }
    return (position.row * columns) + position.column;
  }

  Position indexToPosition(int index) {
    if (index < 0 || index >= rows * columns) {
      throw ArgumentError('Invalid index $index for ${rows}x$columns board');
    }
    return Position(index ~/ columns, index % columns);
  }

  // Cell Management
  BoardCell? getCell(Position position) {
    if (!isValidPosition(position)) return null;
    return _board.cells[positionToIndex(position)];
  }

  void setCell(Position position, BoardCell cell) {
    if (!isValidPosition(position)) return;
    final cells = List<BoardCell>.from(_board.cells);
    cells[positionToIndex(position)] = cell;
    _board = _board.copyWith(cells: cells);
  }

  String? getBlockId(Position position) {
    return getCell(position)?.blockId;
  }

  void setBlockId(Position position, String blockId) {
    final cell = getCell(position);
    if (cell == null) return;
    setCell(position, cell.copyWith(blockId: blockId));
  }

  void clearCell(Position position) {
    final cell = getCell(position);
    if (cell == null) return;
    setCell(position, cell.copyWith(clearBlock: true));
  }

  bool isOccupied(Position position) {
    return getCell(position)?.isOccupied ?? false;
  }

  bool isEmpty(Position position) {
    final cell = getCell(position);
    return cell != null && !cell.isOccupied;
  }

  // Neighbors
  List<Position> getNeighbors(Position position) {
    if (!isValidPosition(position)) return [];
    
    final neighbors = <Position>[];
    
    // UP
    if (position.row > 0) {
      neighbors.add(Position(position.row - 1, position.column));
    }
    
    // DOWN
    if (position.row < rows - 1) {
      neighbors.add(Position(position.row + 1, position.column));
    }
    
    // LEFT
    if (position.column > 0) {
      neighbors.add(Position(position.row, position.column - 1));
    }
    
    // RIGHT
    if (position.column < columns - 1) {
      neighbors.add(Position(position.row, position.column + 1));
    }
    
    return neighbors;
  }

  // Lookups
  Position? findPositionOfBlock(String blockId) {
    for (final cell in _board.cells) {
      if (cell.blockId == blockId) {
        return cell.position;
      }
    }
    return null;
  }

  bool hasBlock(String blockId) {
    return findPositionOfBlock(blockId) != null;
  }

  // Clearing & Reset
  void clearAllCells() {
    final newCells = _board.cells.map((c) => c.copyWith(clearBlock: true)).toList();
    _board = _board.copyWith(cells: newCells);
  }

  void removeBlockReference(String blockId) {
    final pos = findPositionOfBlock(blockId);
    if (pos != null) {
      clearCell(pos);
    }
  }

  void reset() {
    _initialize(rows, columns);
  }

  void resetTo(int newRows, int newColumns) {
    _initialize(newRows, newColumns);
  }

  // State Copy
  Board copyState() {
    return _board.copyWith(
      cells: List<BoardCell>.unmodifiable(_board.cells),
      blocks: Map<String, Block>.unmodifiable(_board.blocks),
    );
  }

  void loadState(Board state) {
    validateBoard(state);
    _board = state;
  }

  // Validation
  void validateBoard([Board? targetBoard]) {
    final boardToCheck = targetBoard ?? _board;
    if (boardToCheck.rows <= 0 || boardToCheck.columns <= 0) {
      throw StateError('Board dimensions must be positive');
    }
    if (boardToCheck.cells.length != boardToCheck.rows * boardToCheck.columns) {
      throw StateError('Cells list size does not match dimensions');
    }
    
    final seenPositions = <String>{};
    for (int i = 0; i < boardToCheck.cells.length; i++) {
      final cell = boardToCheck.cells[i];
      final expectedPos = Position(i ~/ boardToCheck.columns, i % boardToCheck.columns);
      
      if (cell.position != expectedPos) {
        throw StateError('Cell at index $i has incorrect position ${cell.position}');
      }
      
      final posKey = '${cell.position.row},${cell.position.column}';
      if (seenPositions.contains(posKey)) {
        throw StateError('Duplicate position detected: $posKey');
      }
      seenPositions.add(posKey);
    }
  }

  // Iteration
  Iterable<BoardCell> get allCells => _board.cells;

  // Occupancy
  int get occupiedCellCount => _board.cells.where((c) => c.isOccupied).length;
  int get emptyCellCount => _board.cells.where((c) => !c.isOccupied).length;
  bool get isFullBoard => emptyCellCount == 0;
  bool get isEmptyBoard => occupiedCellCount == 0;
}
