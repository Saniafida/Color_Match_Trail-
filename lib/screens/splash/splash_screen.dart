import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    final onboardingManager = ServiceLocator.instance.onboardingManager;
    final destination = onboardingManager.isOnboardingRequired
        ? AppRoutes.onboarding
        : AppRoutes.home;
    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Subtle Dark overlay for contrast
          Container(
            color: Colors.black.withAlpha(40),
          ),

          // 3. Foreground Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // 3D Wooden Logo Sign
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Image.asset(
                    'assets/images/logo_wood.png',
                    height: size.height * 0.22,
                    fit: BoxFit.contain,
                  ),
                ),

                const Spacer(),

                // Mascot Bear sitting holding blocks
                SizedBox(
                  height: size.height * 0.38,
                  child: Image.asset(
                    'assets/images/mascot_bear.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const Spacer(),

                // 3D Wooden Frame Loading Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (context, child) {
                      final percent = (_progressAnim.value * 100).toInt();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Wooden Progress Bar Container
                          Container(
                            height: 28,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D3A1A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFFD54F),
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF331A0B),
                                  offset: Offset(0, 3),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  // Background Track
                                  Container(
                                    color: const Color(0xFF3E200C),
                                  ),
                                  // Active Glossy Green/Gold Progress
                                  FractionallySizedBox(
                                    widthFactor: _progressAnim.value.clamp(0.05, 1.0),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFFEE58),
                                            Color(0xFF8CE03E),
                                            Color(0xFF4CAF50),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Loading Text
                                  Center(
                                    child: Text(
                                      'Loading...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
