import 'package:flutter/material.dart';

/// Dims the entire screen and optionally cuts out a circular highlight area.
class TutorialHighlight extends StatelessWidget {
  final Rect? highlightRect;
  final double dimOpacity;

  const TutorialHighlight({
    super.key,
    this.highlightRect,
    this.dimOpacity = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _HighlightPainter(
          highlightRect: highlightRect,
          dimOpacity: dimOpacity,
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final Rect? highlightRect;
  final double dimOpacity;

  _HighlightPainter({this.highlightRect, required this.dimOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withAlpha((dimOpacity * 255).round());

    if (highlightRect == null) {
      canvas.drawRect(Offset.zero & size, dimPaint);
      return;
    }

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addOval(highlightRect!.inflate(12))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, dimPaint);

    // Glow ring around highlight
    final glowPaint = Paint()
      ..color = Colors.amber.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(highlightRect!.inflate(12), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter old) =>
      old.highlightRect != highlightRect || old.dimOpacity != dimOpacity;
}
