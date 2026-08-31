import 'package:flutter/material.dart';
import '../../models/position.dart';

class TrailInputLayer extends StatelessWidget {
  final int rows;
  final int columns;
  final double cellSize;
  final double cellSpacing;
  final void Function(Position) onDragStart;
  final void Function(Position) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;

  const TrailInputLayer({
    super.key,
    required this.rows,
    required this.columns,
    required this.cellSize,
    this.cellSpacing = 0.0,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  Position? _getLocalPosition(Offset localPosition) {
    final totalCellSize = cellSize + cellSpacing;
    final c = (localPosition.dx / totalCellSize).floor();
    final r = (localPosition.dy / totalCellSize).floor();
    
    if (r >= 0 && r < rows && c >= 0 && c < columns) {
      return Position(r, c);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = columns * (cellSize + cellSpacing) - cellSpacing;
    final height = rows * (cellSize + cellSpacing) - cellSpacing;
    
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        final pos = _getLocalPosition(event.localPosition);
        if (pos != null) onDragStart(pos);
      },
      onPointerMove: (event) {
        final pos = _getLocalPosition(event.localPosition);
        if (pos != null) onDragUpdate(pos);
      },
      onPointerUp: (event) => onDragEnd(),
      onPointerCancel: (event) => onDragCancel(),
      child: SizedBox(
        width: width > 0 ? width : 0,
        height: height > 0 ? height : 0,
      ),
    );
  }
}
