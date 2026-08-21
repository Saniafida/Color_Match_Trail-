import 'package:flutter/material.dart';

class ComboFeedback extends StatefulWidget {
  final int comboLevel;
  final VoidCallback onComplete;

  const ComboFeedback({
    super.key,
    required this.comboLevel,
    required this.onComplete,
  });

  @override
  State<ComboFeedback> createState() => _ComboFeedbackState();
}

class _ComboFeedbackState extends State<ComboFeedback> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.2), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine combo text
    final isMega = widget.comboLevel > 4;
    final text = isMega ? "MEGA CASCADE!" : "CASCADE x\${widget.comboLevel}!";
    final color = isMega ? Colors.purpleAccent : Colors.orangeAccent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: const Alignment(0, -0.6), // Upper screen area
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    const Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
                    Shadow(blurRadius: 20, color: color),
                    Shadow(blurRadius: 40, color: color),
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
