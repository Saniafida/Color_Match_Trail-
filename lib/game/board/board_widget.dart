import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../blocks/block_widget.dart';
import '../trail/trail_input_layer.dart';
import '../trail/trail_renderer.dart';

/// Renders the static background cell grid.
/// This widget is const-constructible and will rarely rebuild.
class _BoardBackground extends StatelessWidget {
  final int rows;
  final int columns;
  final double cellSize;
  final double cellSpacing;

  const _BoardBackground({
    required this.rows,
    required this.columns,
    required this.cellSize,
    required this.cellSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int r = 0; r < rows; r++)
          for (int c = 0; c < columns; c++)
            Positioned(
              left: c * (cellSize + cellSpacing),
              top: r * (cellSize + cellSpacing),
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(cellSize * 0.25),
                ),
              ),
            ),
      ],
    );
  }
}

/// Renders the block grid. Rebuilds only when [board] changes.
class _BoardBlockLayer extends StatelessWidget {
  final Board board;
  final double cellSize;
  final double cellSpacing;

  const _BoardBlockLayer({
    required this.board,
    required this.cellSize,
    required this.cellSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int r = 0; r < board.rows; r++)
          for (int c = 0; c < board.columns; c++)
            if (board.cells[(r * board.columns) + c].isOccupied)
              Positioned(
                left: c * (cellSize + cellSpacing),
                top: r * (cellSize + cellSpacing),
                child: _buildBlockWrapper(board.cells[(r * board.columns) + c].blockId!),
              ),
      ],
    );
  }

  Widget _buildBlockWrapper(String blockId) {
    final block = board.blocks[blockId];
    if (block == null) return SizedBox(width: cellSize, height: cellSize);

    return BlockWidget(
      key: ValueKey(blockId),
      block: block,
      size: cellSize,
    );
  }
}

class BoardWidget extends StatelessWidget {
  final Board board;
  final Trail trail;
  final double cellSize;
  final double cellSpacing;
  final void Function(Position) onDragStart;
  final void Function(Position) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;

  const BoardWidget({
    super.key,
    required this.board,
    required this.trail,
    this.cellSize = 45.0,
    this.cellSpacing = 4.0,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  @override
  Widget build(BuildContext context) {
    final width = board.columns * (cellSize + cellSpacing) - cellSpacing;
    final height = board.rows * (cellSize + cellSpacing) - cellSpacing;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Static background grid — rarely rebuilds
          _BoardBackground(
            rows: board.rows,
            columns: board.columns,
            cellSize: cellSize,
            cellSpacing: cellSpacing,
          ),

          // 2. Block layer — rebuilds only when board state changes
          _BoardBlockLayer(
            board: board,
            cellSize: cellSize,
            cellSpacing: cellSpacing,
          ),

          // 3. Trail layer — isolated in a RepaintBoundary so it can repaint
          //    during drag without causing the block layer above to rebuild.
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: TrailRenderer(
                    trail: trail,
                    cellSize: cellSize,
                    cellSpacing: cellSpacing,
                  ),
                ),
              ),
            ),
          ),

          // 4. Input layer on top
          Positioned.fill(
            child: TrailInputLayer(
              rows: board.rows,
              columns: board.columns,
              cellSize: cellSize,
              cellSpacing: cellSpacing,
              onDragStart: onDragStart,
              onDragUpdate: onDragUpdate,
              onDragEnd: onDragEnd,
              onDragCancel: onDragCancel,
            ),
          ),
        ],
      ),
    );
  }
}
