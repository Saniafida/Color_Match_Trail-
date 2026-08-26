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
  final double width;
  final double height;
  final VoidCallback onTap;

  const LevelNode({
    super.key,
    required this.progress,
    required this.isCurrent,
    this.reducedMotion = false,
    this.width = 34.0,
    this.height = 38.0,
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
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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
    if (widget.isCurrent) return LevelNodeVisualState.current;
    if (widget.progress.completed && widget.progress.bestStars >= 3) return LevelNodeVisualState.perfect;
    if (widget.progress.completed) return LevelNodeVisualState.completed;
    if (widget.progress.unlocked) return LevelNodeVisualState.unlocked;
    return LevelNodeVisualState.locked;
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
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Golden Crown above current active level
              if (state == LevelNodeVisualState.current)
                Positioned(
                  top: -9,
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFB300),
                    size: 13,
                    shadows: [
                      Shadow(color: Color(0x99FF8F00), blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),

              // Main Rounded Tile Box
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: _getGradient(state),
                  border: Border.all(
                    color: _getBorderColor(state),
                    width: widget.isCurrent ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    // Deep drop shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: widget.isCurrent ? 0.35 : 0.2),
                      blurRadius: widget.isCurrent ? 6 : 3,
                      offset: const Offset(0, 2),
                    ),
                    // Current tile golden glow
                    if (widget.isCurrent)
                      const BoxShadow(
                        color: Color(0x66FFB300),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    children: [
                      // Top Gloss highlight
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: widget.height * 0.42,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: state == LevelNodeVisualState.locked ? 0.15 : 0.4),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Content Column (Number + 3 Stars)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Level Number
                            Flexible(
                              child: Text(
                                levelNumber,
                                style: TextStyle(
                                  color: _getTextColor(state),
                                  fontWeight: FontWeight.w900,
                                  fontSize: widget.width * 0.38,
                                  height: 1.05,
                                  shadows: _getTextShadows(state),
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            // 3 Stars row
                            _buildStars(widget.progress.bestStars, state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStars(int stars, LevelNodeVisualState state) {
    final isCompleted = state == LevelNodeVisualState.completed || state == LevelNodeVisualState.perfect;
    final isCurrent = state == LevelNodeVisualState.current;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final earned = (index < stars) || isCompleted || (isCurrent && index < 3);
        final starSize = (widget.width * 0.22).clamp(6.0, 9.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.3),
          child: Icon(
            Icons.star_rounded,
            size: starSize,
            color: earned
                ? const Color(0xFFFFD54F)
                : const Color(0xFFBCAAA4).withValues(alpha: 0.75),
            shadows: earned
                ? const [
                    Shadow(color: Color(0x66E65100), blurRadius: 1.5, offset: Offset(0, 0.8)),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  LinearGradient _getGradient(LevelNodeVisualState state) {
    switch (state) {
      case LevelNodeVisualState.completed:
      case LevelNodeVisualState.perfect:
        // Glossy vibrant green gradient
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF66C82B),
            Color(0xFF439818),
            Color(0xFF33790F),
          ],
          stops: [0.0, 0.6, 1.0],
        );

      case LevelNodeVisualState.current:
        // Glowing warm golden amber gradient
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFCA28),
            Color(0xFFFFA000),
            Color(0xFFFF8F00),
          ],
          stops: [0.0, 0.6, 1.0],
        );

      case LevelNodeVisualState.unlocked:
      case LevelNodeVisualState.locked:
        // Soft warm parchment / tan beige
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF3E7D0),
            Color(0xFFE5D2B4),
            Color(0xFFD6BE9B),
          ],
          stops: [0.0, 0.5, 1.0],
        );
    }
  }

  Color _getBorderColor(LevelNodeVisualState state) {
    switch (state) {
      case LevelNodeVisualState.completed:
      case LevelNodeVisualState.perfect:
        return const Color(0xFF2E6E0B);
      case LevelNodeVisualState.current:
        return const Color(0xFFFFE082);
      case LevelNodeVisualState.unlocked:
      case LevelNodeVisualState.locked:
        return const Color(0xFFC3AC87);
    }
  }

  Color _getTextColor(LevelNodeVisualState state) {
    switch (state) {
      case LevelNodeVisualState.completed:
      case LevelNodeVisualState.perfect:
        return Colors.white;
      case LevelNodeVisualState.current:
        return Colors.white;
      case LevelNodeVisualState.unlocked:
      case LevelNodeVisualState.locked:
        return const Color(0xFF5D4037);
    }
  }

  List<Shadow>? _getTextShadows(LevelNodeVisualState state) {
    switch (state) {
      case LevelNodeVisualState.completed:
      case LevelNodeVisualState.perfect:
        return const [
          Shadow(color: Color(0x991B5E20), blurRadius: 2, offset: Offset(0, 1)),
        ];
      case LevelNodeVisualState.current:
        return const [
          Shadow(color: Color(0x99BF360C), blurRadius: 2, offset: Offset(0, 1)),
        ];
      case LevelNodeVisualState.unlocked:
      case LevelNodeVisualState.locked:
        return const [
          Shadow(color: Color(0x40FFFFFF), blurRadius: 1, offset: Offset(0, 1)),
        ];
    }
  }
}
