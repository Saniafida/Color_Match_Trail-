import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../app/routes/routes.dart';
import '../../game/onboarding/onboarding_step.dart';
import 'widgets/tutorial_message.dart';
import 'widgets/tutorial_hand.dart';
import 'widgets/tutorial_highlight.dart';
import 'widgets/tutorial_progress.dart';
import 'widgets/skip_tutorial_dialog.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _manager = ServiceLocator.instance.onboardingManager;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip() async {
    final shouldSkip = await SkipTutorialDialog.show(context);
    if (shouldSkip) {
      await _manager.skip();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    }
  }

  Future<void> _handleNext() async {
    await _fadeController.reverse();
    await _manager.advanceStep();
    final step = _manager.state.currentStep;
    if (step == OnboardingStep.complete) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
      return;
    }
    if (mounted) {
      setState(() {});
      _fadeController.forward();
    }
  }

  Future<void> _handleComplete() async {
    await _manager.advanceStep();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _manager.state.currentStep;
    final size = MediaQuery.of(context).size;

    if (step == OnboardingStep.complete) {
      return _buildCompleteScreen();
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // Background game board illustration
                _buildIllustration(step, size),

                // Dim overlay with cutout highlight
                TutorialHighlight(highlightRect: _getHighlightRect(step, size)),

                // Animated hand guide
                _buildHand(step, size),

                // Top bar: progress + skip
                _buildTopBar(step),

                // Bottom message card
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      TutorialMessage(
                        title: step.title,
                        description: step.description,
                        showNextButton: _showNextButton(step),
                        onNext: _handleNext,
                      ),
                      const SizedBox(height: 16),
                      TutorialProgress(currentStep: step),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _showNextButton(OnboardingStep step) {
    // Show tap-to-continue on explanation steps (blast, gravity, cascade, complete)
    return const {
      OnboardingStep.blast,
      OnboardingStep.gravity,
      OnboardingStep.cascade,
      OnboardingStep.goals,
      OnboardingStep.moves,
    }.contains(step);
  }

  Widget _buildTopBar(OnboardingStep step) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 64),
            const Text(
              'TUTORIAL',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _handleSkip,
              child: const Text(
                'SKIP',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(OnboardingStep step, Size size) {
    // Simple stylized game board for context
    return Center(
      child: Opacity(
        opacity: 0.35,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: 30,
          itemBuilder: (context, index) {
            final colors = [
              const Color(0xFFE74C3C),
              const Color(0xFF3498DB),
              const Color(0xFF2ECC71),
              const Color(0xFFF39C12),
              const Color(0xFF9B59B6),
            ];
            return Container(
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(10),
              ),
            );
          },
        ),
      ),
    );
  }

  Rect? _getHighlightRect(OnboardingStep step, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    switch (step) {
      case OnboardingStep.connectColors:
      case OnboardingStep.largeMatch:
        // Highlight center of board
        return Rect.fromCenter(center: Offset(cx, cy - 30), width: 200, height: 120);
      case OnboardingStep.goals:
        // Highlight top-right area (where goals HUD typically is)
        return Rect.fromCenter(center: Offset(cx + 80, 80), width: 140, height: 60);
      case OnboardingStep.moves:
        // Highlight top-left area (moves counter)
        return Rect.fromCenter(center: Offset(cx - 80, 80), width: 120, height: 60);
      case OnboardingStep.booster:
        // Highlight bottom bar (booster area)
        return Rect.fromCenter(
            center: Offset(cx, size.height - 180), width: 200, height: 70);
      default:
        return null;
    }
  }

  Widget _buildHand(OnboardingStep step, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    switch (step) {
      case OnboardingStep.connectColors:
        return TutorialHand(
          startPosition: Offset(cx - 60, cy - 50),
          endPosition: Offset(cx + 60, cy - 50),
        );
      case OnboardingStep.largeMatch:
        return TutorialHand(
          startPosition: Offset(cx - 90, cy - 30),
          endPosition: Offset(cx + 90, cy - 30),
        );
      case OnboardingStep.booster:
        return TutorialHand(
          startPosition: Offset(cx - 60, size.height - 200),
          endPosition: Offset(cx, cy),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCompleteScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              const Text(
                'YOU\'RE READY!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Great job! You know everything you need to play Color Match Trail.',
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _handleComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'LET\'S PLAY!',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
