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
            // 1. Selection Glowing Aura
            if (isSelected)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.22),
                  boxShadow: [
                    BoxShadow(
                      color: _style.glow.withValues(alpha: 0.90),
                      blurRadius: 8,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),

            // 2. Display either standalone Power-Up Asset OR Normal Block Asset
            if (isPowerUp)
              _buildPowerUpBadge(size * 0.95)
            else
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

            // 3. Selection Outline Border
            if (isSelected)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 2.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerUpBadge(double iconSize) {
    String assetPath;

    switch (widget.block.specialType) {
      case SpecialBlockType.smallArea:
      case SpecialBlockType.horizontalLine:
      case SpecialBlockType.verticalLine:
        assetPath = 'assets/images/power_ups/powerup_4_rocket.png';
        break;
      case SpecialBlockType.bomb:
        assetPath = 'assets/images/power_ups/powerup_5_bomb.png';
        break;
      case SpecialBlockType.crossBlast:
        assetPath = 'assets/images/power_ups/powerup_6_cross.png';
        break;
      case SpecialBlockType.colorSpecial:
        assetPath = 'assets/images/power_ups/powerup_7_color_bomb.png';
        break;
      case SpecialBlockType.megaBomb:
        assetPath = 'assets/images/power_ups/powerup_8_disco_mega.png';
        break;
      case SpecialBlockType.magicWand:
        assetPath = 'assets/images/power_ups/powerup_9_star_wand.png';
        break;
      case SpecialBlockType.none:
        switch (widget.block.type) {
          case BlockType.rocket:
            assetPath = 'assets/images/power_ups/powerup_4_rocket.png';
            break;
          case BlockType.bomb:
            assetPath = 'assets/images/power_ups/powerup_5_bomb.png';
            break;
          case BlockType.colorBomb:
            assetPath = 'assets/images/power_ups/powerup_7_color_bomb.png';
            break;
          case BlockType.otherSpecial:
            assetPath = 'assets/images/power_ups/powerup_9_star_wand.png';
            break;
          default:
            assetPath = 'assets/images/power_ups/powerup_4_rocket.png';
        }
    }

    return Image.asset(
      assetPath,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

