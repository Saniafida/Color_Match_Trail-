import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/progression/level_progress.dart';

enum LevelNodeVisualState {
  locked,
  unlocked,
  current,
  completed,
  perfect,
}

class LevelNode extends StatefulWidget {
  final LevelProgress progress;
  final bool isCurrent;
  final bool reducedMotion;
  final VoidCallback onTap;

  const LevelNode({
    super.key,
    required this.progress,
    required this.isCurrent,
    this.reducedMotion = false,
    required this.onTap,
  });

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isCurrent && !widget.reducedMotion) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !widget.reducedMotion) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  LevelNodeVisualState get _visualState {
    if (!widget.progress.unlocked) return LevelNodeVisualState.locked;
    if (widget.progress.stars >= 3) return LevelNodeVisualState.perfect;
    if (widget.progress.completed) return LevelNodeVisualState.completed;
    if (widget.isCurrent) return LevelNodeVisualState.current;
    return LevelNodeVisualState.unlocked;
  }

  @override
  Widget build(BuildContext context) {
    final state = _visualState;
    final levelNumber = widget.progress.levelId.replaceAll(RegExp(r'[^0-9]'), '');

    return Semantics(
      label: 'Level $levelNumber, ${state.name}',
      button: true,
      enabled: widget.progress.unlocked,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = (widget.isCurrent && !widget.reducedMotion) ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _getGradient(state),
              border: Border.all(
                color: _getBorderColor(state),
                width: widget.isCurrent ? 3.5 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getGlowColor(state),
                  blurRadius: widget.isCurrent ? 12 : 6,
                  spreadRadius: widget.isCurrent ? 2 : 0,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state == LevelNodeVisualState.locked) ...[
                      const Icon(Icons.lock_rounded, color: Colors.white60, size: 28),
                    ] else ...[
                      Text(
                        levelNumber,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildStars(widget.progress.bestStars),
                    ],
                  ],
                ),
                // Completed Checkmark Badge
                if (widget.progress.completed && state != LevelNodeVisualState.perfect)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
                // Perfect Crown Badge
                if (state == LevelNodeVisualState.perfect)
                  Positioned(
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star, color: Colors.deepOrange, size: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStars(int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final earned = index < stars;
        return Icon(
          Icons.star_rounded,
          size: 13,
          color: earned ? const Color(0xFFFFD700) : Colors.white24,
        );
      }),
    );
  }

  LinearGradient _getGradient(LevelNodeVisualState state) {
    switch (state) {
      case LevelNodeVisualState.locked:
        return const LinearGradient(
          colors: [Color(0xFF424242), Color(0xFF212121)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LevelNodeVisualState.unlocked:
        return const LinearGradient(
          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LevelNodeVisualState.current:
        return const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFF4511E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LevelNodeVisualState.completed:
        return const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LevelNodeVisualState.perfect:
        return const LinearGradient(
          colors: [Color(0xFFFFCA28), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getBorderColor(LevelNodeVisualState state) {
    switch (state) {
      case LevelNodeVisualState.locked:
        return Colors.white24;
      case LevelNodeVisualState.unlocked:
        return Colors.white70;
      case LevelNodeVisualState.current:
        return Colors.white;
      case LevelNodeVisualState.completed:
        return const Color(0xFF80CBC4);
      case LevelNodeVisualState.perfect:
        return const Color(0xFFFFF9C4);
    }
  }

  Color _getGlowColor(LevelNodeVisualState state) {
    switch (state) {
      case LevelNodeVisualState.locked:
        return Colors.transparent;
      case LevelNodeVisualState.unlocked:
        return const Color(0x660288D1);
      case LevelNodeVisualState.current:
        return const Color(0x99F4511E);
      case LevelNodeVisualState.completed:
        return const Color(0x6600897B);
      case LevelNodeVisualState.perfect:
        return const Color(0x80FFA000);
    }
  }
}
