import 'package:flutter/material.dart';

class HomeLogo extends StatefulWidget {
  const HomeLogo({super.key});

  @override
  State<HomeLogo> createState() => _HomeLogoState();
}

class _HomeLogoState extends State<HomeLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: const Text(
        'COLOR MATCH\nTRAIL',
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.1,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
