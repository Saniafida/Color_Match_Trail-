import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScreenShakeController extends ChangeNotifier {
  double _intensity = 0.0;
  double get intensity => _intensity;

  /// Trigger subtle or strong screen shake (120-150ms)
  void shake({double intensity = 6.0}) {
    _intensity = intensity;
    notifyListeners();
  }

  void decay() {
    if (_intensity > 0.0) {
      _intensity = 0.0;
      notifyListeners();
    }
  }
}

class ScreenShakeContainer extends StatefulWidget {
  final ScreenShakeController controller;
  final Widget child;

  const ScreenShakeContainer({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<ScreenShakeContainer> createState() => _ScreenShakeContainerState();
}

class _ScreenShakeContainerState extends State<ScreenShakeContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  double _currentIntensity = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    widget.controller.addListener(_handleShakeTrigger);
  }

  void _handleShakeTrigger() {
    if (widget.controller.intensity > 0) {
      _currentIntensity = widget.controller.intensity;
      widget.controller.decay();
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleShakeTrigger);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        if (!_animController.isAnimating) {
          return child!;
        }

        final decay = 1.0 - _animController.value;
        final offsetMagnitude = _currentIntensity * decay;
        final angle = _animController.value * 8 * math.pi;
        final dx = math.cos(angle) * offsetMagnitude;
        final dy = math.sin(angle * 1.5) * offsetMagnitude * 0.7;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
