import 'package:flutter/material.dart';

class TutorialHand extends StatefulWidget {
  final Offset startPosition;
  final Offset? endPosition;
  final bool visible;

  const TutorialHand({
    super.key,
    required this.startPosition,
    this.endPosition,
    this.visible = true,
  });

  @override
  State<TutorialHand> createState() => _TutorialHandState();
}

class _TutorialHandState extends State<TutorialHand>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition ?? widget.startPosition,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: const _HandIcon(),
          ),
        );
      },
    );
  }
}

class _HandIcon extends StatelessWidget {
  const _HandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.touch_app, color: Colors.white, size: 28),
    );
  }
}
