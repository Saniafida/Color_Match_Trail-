import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'block_color_mapper.dart';

class BlockWidget extends StatefulWidget {
  final Block block;
  final double size;

  const BlockWidget({
    super.key,
    required this.block,
    required this.size,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late BlockStyle _style;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _style = BlockColorMapper.getStyle(widget.block.color);
    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.block.color != oldWidget.block.color) {
      _style = BlockColorMapper.getStyle(widget.block.color);
    }

    if (widget.block.isSelected != oldWidget.block.isSelected) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.block.isSelected) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final bool isLocked = widget.block.isLocked;
    final bool isSelected = widget.block.isSelected;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final currentScale = widget.block.isBeingDestroyed ? 0.0 : _scaleAnimation.value;
        return Transform.scale(
          scale: currentScale,
          child: child,
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Full-size 3D Painted Block Canvas (No inner padding for tight grid)
            Positioned.fill(
              child: CustomPaint(
                painter: _Block3DPainter(
                  style: _style,
                  isLocked: isLocked,
                  isSelected: isSelected,
                ),
              ),
            ),

            // 2. Debossed / Engraved Center Icon
            Center(
              child: _buildDebossedIcon(size, isLocked),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the 3D debossed (engraved / pressed-in) icon
  Widget _buildDebossedIcon(double size, bool isLocked) {
    final iconSize = size * 0.48;

    // Special blocks
    if (widget.block.type != BlockType.normal) {
      return _buildSpecialBlockIcon(iconSize, isLocked);
    }

    final iconData = _style.normalIcon;

    return SizedBox(
      width: iconSize + 4,
      height: iconSize + 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pass 1: Bottom-Right Rim Highlight (Light catching the lower groove edge)
          Transform.translate(
            offset: const Offset(0.0, 1.2),
            child: Icon(
              iconData,
              size: iconSize,
              color: isLocked
                  ? _style.iconHighlight.withValues(alpha: 0.25)
                  : _style.iconHighlight.withValues(alpha: 0.60),
            ),
          ),

          // Pass 2: Top-Left Dark Inset Shadow (Shadow under upper carved edge)
          Transform.translate(
            offset: const Offset(-0.4, -0.8),
            child: Icon(
              iconData,
              size: iconSize,
              color: isLocked
                  ? _style.iconShadow.withValues(alpha: 0.35)
                  : _style.iconShadow.withValues(alpha: 0.80),
            ),
          ),

          // Pass 3: Main Debossed Icon Body (Deep rich tone matching the cube)
          Icon(
            iconData,
            size: iconSize,
            color: isLocked
                ? _style.iconMain.withValues(alpha: 0.45)
                : _style.iconMain.withValues(alpha: 0.95),
          ),
        ],
      ),
    );
  }

  /// Builds icons for Special Blocks (Rocket, Bomb, Color Bomb)
  Widget _buildSpecialBlockIcon(double iconSize, bool isLocked) {
    IconData specialIcon;
    Color iconColor;

    switch (widget.block.type) {
      case BlockType.rocket:
        specialIcon = Icons.rocket_launch_rounded;
        iconColor = Colors.white;
        break;
      case BlockType.bomb:
        specialIcon = Icons.local_fire_department_rounded;
        iconColor = Colors.amberAccent;
        break;
      case BlockType.colorBomb:
        specialIcon = Icons.auto_awesome;
        iconColor = Colors.yellowAccent;
        break;
      default:
        specialIcon = Icons.star_rounded;
        iconColor = Colors.white;
    }

    return SizedBox(
      width: iconSize + 6,
      height: iconSize + 6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            specialIcon,
            size: iconSize * 1.15,
            color: Colors.black.withValues(alpha: 0.65),
          ),
          Icon(
            specialIcon,
            size: iconSize,
            color: isLocked ? iconColor.withValues(alpha: 0.5) : iconColor,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom 3D Painter creating a Toy / Candy Cube with bevels and cushion lighting
class _Block3DPainter extends CustomPainter {
  final BlockStyle style;
  final bool isLocked;
  final bool isSelected;

  _Block3DPainter({
    required this.style,
    required this.isLocked,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.11; // Subtle corner radius matching screenshot
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // 1. Drop shadow behind the cube
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);

    // 2. Neon halo glow when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = style.glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawRRect(rrect, glowPaint);
    }

    // 3. BASE BEVEL (Top-Left Highlight -> Bottom-Right Deep Shadow)
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.45, 1.0],
        colors: [
          isLocked ? style.highlight.withValues(alpha: 0.5) : style.highlight,
          isLocked ? style.main.withValues(alpha: 0.5) : style.main,
          isLocked ? style.shadow.withValues(alpha: 0.5) : style.shadow,
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, basePaint);

    // 4. 3D BEVEL EDGES (Light top/left rim & Dark bottom/right rim)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.4, 0.7, 1.0],
        colors: [
          Colors.white.withValues(alpha: isLocked ? 0.25 : 0.65),
          Colors.white.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: isLocked ? 0.25 : 0.60),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(0.9), rimPaint);

    // 5. INNER CUSHION / PILLOW (Puffed center face)
    final innerInset = w * 0.08;
    final innerRect = Rect.fromLTWH(innerInset, innerInset, w - (innerInset * 2), h - (innerInset * 2));
    final innerRRect = RRect.fromRectAndRadius(innerRect, Radius.circular(r * 0.7));

    final innerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 0.9,
        stops: const [0.0, 0.65, 1.0],
        colors: [
          isLocked ? style.highlight.withValues(alpha: 0.5) : style.highlight,
          isLocked ? style.main.withValues(alpha: 0.5) : style.main,
          isLocked
              ? Color.lerp(style.main, style.shadow, 0.6)!.withValues(alpha: 0.5)
              : Color.lerp(style.main, style.shadow, 0.6)!,
        ],
      ).createShader(innerRect);
    canvas.drawRRect(innerRRect, innerPaint);

    // 6. TOP SPECULAR GLOSS (Curved reflection on upper half)
    final glossRect = Rect.fromLTWH(innerInset, innerInset, w - (innerInset * 2), (h - innerInset * 2) * 0.5);
    final glossRRect = RRect.fromRectAndRadius(glossRect, Radius.circular(r * 0.6));
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isLocked ? 0.15 : 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(glossRect);
    canvas.drawRRect(glossRRect, glossPaint);

    // 7. SELECTION OUTLINE
    if (isSelected) {
      final selectPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.95);
      canvas.drawRRect(rrect.deflate(1.2), selectPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Block3DPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.isSelected != isSelected;
  }
}
