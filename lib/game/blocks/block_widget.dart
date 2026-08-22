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
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
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
        widget.block.isInTrail != oldWidget.block.isInTrail ||
        widget.block.isTransforming != oldWidget.block.isTransforming) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.block.isTransforming || widget.block.isSelected || widget.block.isInTrail) {
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
    final bool isSelected = widget.block.isSelected || widget.block.isInTrail;
    final bool isTransforming = widget.block.isTransforming;
    final bool isPowerUp = widget.block.isPowerUp;

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
            // 1. Selection / Trail Glowing Aura
            if (isSelected || isPowerUp)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.22),
                  boxShadow: [
                    BoxShadow(
                      color: isPowerUp
                          ? const Color(0xFFFFD700).withValues(alpha: 0.85)
                          : _style.glow.withValues(alpha: 0.90),
                      blurRadius: isPowerUp ? 10 : 8,
                      spreadRadius: isPowerUp ? 2 : 1.5,
                    ),
                  ],
                ),
              ),

            // 2. Main 3D Block PNG Image Asset from assets/blocks/
            Opacity(
              opacity: isLocked ? 0.45 : 1.0,
              child: Image.asset(
                _style.assetPath,
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),

            // 3. Selection / Power-Up Outline Border
            if (isSelected || isPowerUp)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.22),
                  border: Border.all(
                    color: isPowerUp
                        ? const Color(0xFFFFEB3B)
                        : Colors.white.withValues(alpha: 0.95),
                    width: 2.2,
                  ),
                ),
              ),

            // 4. Special Power-Up Emblem Badge Overlay (if power-up block)
            if (isPowerUp)
              Center(
                child: _buildPowerUpBadge(size * 0.55),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerUpBadge(double iconSize) {
    IconData icon;
    Color color;

    switch (widget.block.specialType) {
      case SpecialBlockType.smallArea:
      case SpecialBlockType.horizontalLine:
      case SpecialBlockType.verticalLine:
        icon = Icons.rocket_launch_rounded;
        color = Colors.white;
        break;
      case SpecialBlockType.bomb:
        icon = Icons.local_fire_department_rounded;
        color = const Color(0xFFFFD700);
        break;
      case SpecialBlockType.crossBlast:
        icon = Icons.control_camera_rounded;
        color = const Color(0xFF00E5FF);
        break;
      case SpecialBlockType.colorSpecial:
        icon = Icons.auto_awesome;
        color = const Color(0xFFFF4081);
        break;
      case SpecialBlockType.megaBomb:
        icon = Icons.stars_rounded;
        color = const Color(0xFFFFD700);
        break;
      case SpecialBlockType.none:
        switch (widget.block.type) {
          case BlockType.rocket:
            icon = Icons.rocket_launch_rounded;
            color = Colors.white;
            break;
          case BlockType.bomb:
            icon = Icons.local_fire_department_rounded;
            color = const Color(0xFFFFD700);
            break;
          case BlockType.colorBomb:
            icon = Icons.auto_awesome;
            color = const Color(0xFFFF4081);
            break;
          default:
            icon = Icons.star_rounded;
            color = Colors.white;
        }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          icon,
          size: iconSize * 1.15,
          color: Colors.black.withValues(alpha: 0.75),
        ),
        Icon(
          icon,
          size: iconSize,
          color: color,
          shadows: const [
            Shadow(
              color: Colors.black87,
              blurRadius: 4,
              offset: Offset(1, 2),
            ),
          ],
        ),
      ],
    );
  }
}

