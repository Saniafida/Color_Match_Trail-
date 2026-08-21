import 'package:flutter/material.dart';
import '../../../../game/feedback/feedback_config.dart';

class FloatingFeedback extends StatefulWidget {
  final String text;
  final VoidCallback onComplete;

  const FloatingFeedback({
    super.key,
    required this.text,
    required this.onComplete,
  });

  @override
  State<FloatingFeedback> createState() => _FloatingFeedbackState();
}

class _FloatingFeedbackState extends State<FloatingFeedback> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FeedbackConfig.floatDuration,
    );

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _translateY = Tween<double>(begin: 20, end: -50).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(2, 2)),
                    Shadow(blurRadius: 20, color: Colors.orange),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
