import 'package:flutter/material.dart';
import '../../../game/achievements/achievement_definition.dart';
import '../../../core/services/service_locator.dart';

class AchievementUnlockOverlay {
  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  static void initialize(BuildContext context) {
    final overlay = Overlay.of(context);
    ServiceLocator.instance.achievementManager.unlockStream.listen((def) {
      _show(overlay, def);
    });
  }

  static void _show(OverlayState overlay, AchievementDefinition def) {
    if (_isShowing) return;
    
    _isShowing = true;
    _currentEntry = OverlayEntry(
      builder: (context) => _AchievementPopupWidget(
        definition: def,
        onComplete: () {
          _currentEntry?.remove();
          _currentEntry = null;
          _isShowing = false;
        },
      ),
    );

    overlay.insert(_currentEntry!);
  }
}

class _AchievementPopupWidget extends StatefulWidget {
  final AchievementDefinition definition;
  final VoidCallback onComplete;

  const _AchievementPopupWidget({
    required this.definition,
    required this.onComplete,
  });

  @override
  State<_AchievementPopupWidget> createState() => _AchievementPopupWidgetState();
}

class _AchievementPopupWidgetState extends State<_AchievementPopupWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation = Tween<double>(begin: -100, end: 50).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onComplete());
      }
    });
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
        return Positioned(
          top: _slideAnimation.value,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2735),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ACHIEVEMENT UNLOCKED',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.definition.titleKey,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
