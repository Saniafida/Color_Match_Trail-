import 'package:flutter/material.dart';

class LevelPathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final List<bool> nodeUnlocked;
  final Color activeColor;
  final Color inactiveColor;

  const LevelPathPainter({
    required this.nodePositions,
    required this.nodeUnlocked,
    this.activeColor = const Color(0xFFFFCA28),
    this.inactiveColor = const Color(0xFF546E7A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final p1 = nodePositions[i];
      final p2 = nodePositions[i + 1];
      final isSegmentUnlocked = i < nodeUnlocked.length && nodeUnlocked[i] && (i + 1 < nodeUnlocked.length && nodeUnlocked[i + 1]);

      final paint = Paint()
        ..color = isSegmentUnlocked ? activeColor : inactiveColor
        ..strokeWidth = isSegmentUnlocked ? 4.5 : 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw smooth cubic or quadratic bezier curve between nodes
      final path = Path();
      path.moveTo(p1.dx, p1.dy);

      final controlX = (p1.dx + p2.dx) / 2;
      final controlY = (p1.dy + p2.dy) / 2 + ((i % 2 == 0) ? 25 : -25);

      path.quadraticBezierTo(controlX, controlY, p2.dx, p2.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LevelPathPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions || oldDelegate.nodeUnlocked != nodeUnlocked;
  }
}
