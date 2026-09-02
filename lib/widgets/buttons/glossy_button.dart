import 'package:flutter/material.dart';

enum GlossyButtonColor {
  green,
  blue,
  gold,
  wood,
  red,
}

class GlossyButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final GlossyButtonColor color;
  final Widget? icon;
  final double height;
  final double? width;
  final double fontSize;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlossyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = GlossyButtonColor.green,
    this.icon,
    this.height = 54,
    this.width,
    this.fontSize = 20,
    this.borderRadius = 28,
    this.padding,
  });

  @override
  State<GlossyButton> createState() => _GlossyButtonState();
}

class _GlossyButtonState extends State<GlossyButton> {
  bool _isPressed = false;

  (List<Color>, Color, Color) _getColors() {
    switch (widget.color) {
      case GlossyButtonColor.green:
        return (
          [const Color(0xFF8CE03E), const Color(0xFF5CB811), const Color(0xFF388E02)],
          const Color(0xFF235B00),
          const Color(0xFFB4F577),
        );
      case GlossyButtonColor.blue:
        return (
          [const Color(0xFF4FC3F7), const Color(0xFF0288D1), const Color(0xFF01579B)],
          const Color(0xFF002F6C),
          const Color(0xFFB3E5FC),
        );
      case GlossyButtonColor.gold:
        return (
          [const Color(0xFFFFE082), const Color(0xFFFFB300), const Color(0xFFFF8F00)],
          const Color(0xFFB26A00),
          const Color(0xFFFFF9C4),
        );
      case GlossyButtonColor.red:
        return (
          [const Color(0xFFFF8A80), const Color(0xFFE53935), const Color(0xFFC62828)],
          const Color(0xFF7F0000),
          const Color(0xFFFFCDD2),
        );
      case GlossyButtonColor.wood:
        return (
          [const Color(0xFFB57C3E), const Color(0xFF8B5A2B), const Color(0xFF5D3A1A)],
          const Color(0xFF3E200C),
          const Color(0xFFD7A876),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (gradientColors, bottomShadowColor, highlightColor) = _getColors();
    final double currentOffset = _isPressed ? 2.0 : 5.0;

    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null ? null : (_) {
        setState(() => _isPressed = false);
        widget.onPressed!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: highlightColor.withAlpha(180),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: bottomShadowColor,
              offset: Offset(0, currentOffset),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(80),
              offset: Offset(0, currentOffset + 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: widget.icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.icon!,
                      const SizedBox(width: 6),
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: bottomShadowColor,
                              offset: const Offset(1, 2),
                              blurRadius: 2,
                            ),
                            const Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: bottomShadowColor,
                          offset: const Offset(1, 2),
                          blurRadius: 2,
                        ),
                        const Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
