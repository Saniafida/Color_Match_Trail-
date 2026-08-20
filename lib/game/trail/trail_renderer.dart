import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../blocks/block_color_mapper.dart';

class TrailRenderer extends CustomPainter {
  final Trail trail;
  final double cellSize;
  final double cellSpacing;

  TrailRenderer({
    required this.trail,
    required this.cellSize,
    required this.cellSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.positions.length < 2 || trail.color == null) return;

    final style = BlockColorMapper.getStyle(trail.color!);
    final totalCellSize = cellSize + cellSpacing;
    final halfCell = cellSize / 2;

    Offset getCenter(Position pos) {
      final x = (pos.column * totalCellSize) + halfCell;
      final y = (pos.row * totalCellSize) + halfCell;
      return Offset(x, y);
    }

    final path = Path();
    final startOffset = getCenter(trail.positions.first);
    path.moveTo(startOffset.dx, startOffset.dy);

    for (int i = 1; i < trail.positions.length; i++) {
      final offset = getCenter(trail.positions[i]);
      path.lineTo(offset.dx, offset.dy);
    }

    // Glow layer behind the trail
    final glowPaint = Paint()
      ..color = style.glow
      ..strokeWidth = cellSize * 0.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, glowPaint);

    // Main glossy trail line
    final mainPaint = Paint()
      ..color = style.highlight
      ..strokeWidth = cellSize * 0.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, mainPaint);
  }

  @override
  bool shouldRepaint(covariant TrailRenderer oldDelegate) {
    return oldDelegate.trail != trail || 
           oldDelegate.cellSize != cellSize || 
           oldDelegate.cellSpacing != cellSpacing;
  }
}
