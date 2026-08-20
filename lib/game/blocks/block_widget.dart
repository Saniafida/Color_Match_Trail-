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

  // Cached decorations to avoid rebuilding on every frame
  late BoxDecoration _decoration;
  late BoxDecoration _innerDecoration;
  late BlockStyle _style;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _style = BlockColorMapper.getStyle(widget.block.color);
    _rebuildDecorations();
    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only recompute decorations if the block's visual state changed
    if (widget.block.isSelected != oldWidget.block.isSelected ||
        widget.block.isLocked != oldWidget.block.isLocked ||
        widget.block.color != oldWidget.block.color) {
      _style = BlockColorMapper.getStyle(widget.block.color);
      _rebuildDecorations();
    }

    if (widget.block.isSelected != oldWidget.block.isSelected) {
      _updateAnimationState();
    }
  }

  void _rebuildDecorations() {
    final bool isLocked = widget.block.isLocked;
    final bool isSelected = widget.block.isSelected;

    _decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(widget.size * 0.25),
      color: isLocked ? _style.main.withValues(alpha: 0.5) : _style.main,
      boxShadow: [
        if (isSelected)
          BoxShadow(
            color: _style.glow,
            blurRadius: widget.size * 0.2,
            spreadRadius: widget.size * 0.05,
          ),
        BoxShadow(
          color: Colors.black26,
          blurRadius: widget.size * 0.1,
          offset: Offset(0, widget.size * 0.08),
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isLocked ? _style.highlight.withValues(alpha: 0.5) : _style.highlight,
          isLocked ? _style.main.withValues(alpha: 0.5) : _style.main,
          isLocked ? _style.shadow.withValues(alpha: 0.5) : _style.shadow,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );

    _innerDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(widget.size * 0.15),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isLocked ? 0.2 : 0.4),
          Colors.transparent,
        ],
      ),
    );
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
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final currentScale = widget.block.isBeingDestroyed ? 0.0 : _scaleAnimation.value;
        return Transform.scale(
          scale: currentScale,
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(widget.size * 0.04),
        child: Container(
          decoration: _decoration,
          child: Container(
            margin: EdgeInsets.all(widget.size * 0.08),
            decoration: _innerDecoration,
            child: _buildSpecialIcon(),
          ),
        ),
      ),
    );
  }

  Widget? _buildSpecialIcon() {
    if (widget.block.type == BlockType.normal) return null;

    IconData iconData;
    switch (widget.block.type) {
      case BlockType.rocket:
        iconData = Icons.rocket_launch;
        break;
      case BlockType.bomb:
        iconData = Icons.local_fire_department;
        break;
      case BlockType.colorBomb:
        iconData = Icons.stars;
        break;
      default:
        iconData = Icons.star;
    }

    return Center(
      child: Icon(
        iconData,
        color: Colors.white70,
        size: widget.size * 0.4,
      ),
    );
  }
}
