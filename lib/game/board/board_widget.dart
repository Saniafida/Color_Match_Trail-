import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../blocks/block_widget.dart';
import '../trail/trail_input_layer.dart';
import '../trail/trail_renderer.dart';

/// Renders the static background cell grid.
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
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(cellSize * 0.11),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.15),
                    width: 1,
                  ),
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
    this.cellSize = 48.0,
    this.cellSpacing = 3.0,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  @override
  Widget build(BuildContext context) {
    final width = board.columns * (cellSize + cellSpacing) - cellSpacing;
    final height = board.rows * (cellSize + cellSpacing) - cellSpacing;

    return Container(
      padding: const EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1712), // Deep warm tray bed
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC7A774), // Golden / wood bezel
          width: 4.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0xFFDFC298),
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SizedBox(
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

            // 3. Trail layer — isolated in a RepaintBoundary
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
      ),
    );
  }
}
