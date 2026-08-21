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
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
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

    if (widget.block.isSelected != oldWidget.block.isSelected ||
        widget.block.isTransforming != oldWidget.block.isTransforming) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.block.isTransforming) {
      _controller.forward();
    } else if (widget.block.isSelected) {
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
    final bool isTransforming = widget.block.isTransforming;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        double currentScale = 1.0;
        if (widget.block.isBeingDestroyed) {
          currentScale = 0.0;
        } else if (isTransforming) {
          currentScale = _scaleAnimation.value * 1.08;
        } else if (isSelected) {
          currentScale = _scaleAnimation.value;
        }

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
            // 1. Full-size 3D Painted Block Canvas
            Positioned.fill(
              child: CustomPaint(
                painter: _Block3DPainter(
                  style: _style,
                  isLocked: isLocked,
                  isSelected: isSelected || isTransforming,
                  isPowerUp: widget.block.isPowerUp,
                ),
              ),
            ),

            // 2. Debossed / Power-Up Center Icon
            Center(
              child: _buildCenterIcon(size, isLocked),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterIcon(double size, bool isLocked) {
    final iconSize = size * 0.50;

    // Special / Power-Up block icon
    if (widget.block.specialType != SpecialBlockType.none || widget.block.type != BlockType.normal) {
      return _buildPowerUpIcon(iconSize, isLocked);
    }

    final iconData = _style.normalIcon;

    return SizedBox(
      width: iconSize + 4,
      height: iconSize + 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rim Highlight
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
          // Inset Shadow
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
          // Main Body
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

  Widget _buildPowerUpIcon(double iconSize, bool isLocked) {
    IconData powerUpIcon;
    Color iconColor;

    switch (widget.block.specialType) {
      case SpecialBlockType.smallArea:
      case SpecialBlockType.horizontalLine:
      case SpecialBlockType.verticalLine:
        powerUpIcon = Icons.rocket_launch_rounded;
        iconColor = Colors.white;
        break;
      case SpecialBlockType.bomb:
        powerUpIcon = Icons.local_fire_department_rounded;
        iconColor = const Color(0xFFFFD700);
        break;
      case SpecialBlockType.crossBlast:
        powerUpIcon = Icons.control_camera_rounded;
        iconColor = const Color(0xFF00E5FF);
        break;
      case SpecialBlockType.colorSpecial:
        powerUpIcon = Icons.auto_awesome;
        iconColor = const Color(0xFFFF4081);
        break;
      case SpecialBlockType.megaBomb:
        powerUpIcon = Icons.stars_rounded;
        iconColor = const Color(0xFFFFD700);
        break;
      case SpecialBlockType.none:
        switch (widget.block.type) {
          case BlockType.rocket:
            powerUpIcon = Icons.rocket_launch_rounded;
            iconColor = Colors.white;
            break;
          case BlockType.bomb:
            powerUpIcon = Icons.local_fire_department_rounded;
            iconColor = const Color(0xFFFFD700);
            break;
          case BlockType.colorBomb:
            powerUpIcon = Icons.auto_awesome;
            iconColor = const Color(0xFFFF4081);
            break;
          default:
            powerUpIcon = Icons.star_rounded;
            iconColor = Colors.white;
        }
    }

    return SizedBox(
      width: iconSize + 6,
      height: iconSize + 6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            powerUpIcon,
            size: iconSize * 1.15,
            color: Colors.black.withValues(alpha: 0.65),
          ),
          Icon(
            powerUpIcon,
            size: iconSize,
            color: isLocked ? iconColor.withValues(alpha: 0.5) : iconColor,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Block3DPainter extends CustomPainter {
  final BlockStyle style;
  final bool isLocked;
  final bool isSelected;
  final bool isPowerUp;

  _Block3DPainter({
    required this.style,
    required this.isLocked,
    required this.isSelected,
    this.isPowerUp = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.12;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // 1. Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);

    // 2. Power-Up / Selection Glow
    if (isPowerUp || isSelected) {
      final glowPaint = Paint()
        ..color = isPowerUp ? const Color(0x99FFD700) : style.glow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isPowerUp ? 10.0 : 8.0);
      canvas.drawRRect(rrect, glowPaint);
    }

    // 3. BASE BEVEL
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

    // 4. 3D BEVEL EDGES
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPowerUp ? 2.2 : 1.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.4, 0.7, 1.0],
        colors: [
          isPowerUp ? const Color(0xFFFFF9C4) : Colors.white.withValues(alpha: isLocked ? 0.25 : 0.65),
          Colors.white.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: isLocked ? 0.25 : 0.60),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(0.9), rimPaint);

    // 5. INNER CUSHION
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

    // 6. TOP SPECULAR GLOSS
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

    // 7. SELECTION / POWER-UP OUTLINE
    if (isSelected || isPowerUp) {
      final selectPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isPowerUp ? 2.0 : 2.5
        ..color = isPowerUp ? const Color(0xFFFFD700).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95);
      canvas.drawRRect(rrect.deflate(1.2), selectPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Block3DPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isPowerUp != isPowerUp;
  }
}
