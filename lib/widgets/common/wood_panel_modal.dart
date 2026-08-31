import 'package:flutter/material.dart';
import 'game_top_bar.dart';
import 'game_bottom_nav_bar.dart';

class WoodPanelModal extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final GameBottomTab activeTab;
  final VoidCallback? onClose;
  final Widget? bottomButton;
  final Widget? footerInfo;

  const WoodPanelModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.activeTab,
    this.onClose,
    this.bottomButton,
    this.footerInfo,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden Nature Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Translucent Dark Overlay
          Container(
            color: Colors.black.withAlpha(90),
          ),

          // 3. Main Screen Flow
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                const GameTopBar(),

                const SizedBox(height: 6),

                // Main Wood Dialog Board
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Wooden Card Body
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6A3B14),
                                Color(0xFF4A250B),
                                Color(0xFF331705),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFFD54F),
                              width: 3.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF1E0C02),
                                offset: Offset(0, 6),
                                blurRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black54,
                                offset: Offset(0, 10),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 48), // Space for top sign overlap

                              // Subtitle Text
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFFECB3),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Inner Content Area
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: child,
                                ),
                              ),

                              // Optional Bottom Action Button
                              if (bottomButton != null) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                                  child: bottomButton!,
                                ),
                              ],

                              // Optional Footer Info
                              if (footerInfo != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: footerInfo!,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Top Wooden Banner with Leaves & Jasmine Flowers
                        Positioned(
                          top: -18,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildHeaderBanner(),
                          ),
                        ),

                        // Red Glossy Close (X) Button in top right
                        Positioned(
                          top: -10,
                          right: -4,
                          child: _buildCloseButton(context),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Bottom 5-Tab Navigation Bar
                GameBottomNavBar(activeTab: activeTab),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Foliage & Flower Garland
        Positioned(
          top: -10,
          left: -14,
          right: -14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLeafCluster(),
              _buildLeafCluster(isFlipped: true),
            ],
          ),
        ),

        // Wood Signboard
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFB57C3E),
                Color(0xFF8B5A2B),
                Color(0xFF6B4226),
                Color(0xFF4A2A12),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFFE082),
              width: 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF261205),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 5),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              shadows: [
                Shadow(color: Color(0xFF331A0B), offset: Offset(1.5, 2.5), blurRadius: 1),
                Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeafCluster({bool isFlipped = false}) {
    return Transform.scale(
      scaleX: isFlipped ? -1 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -0.4,
            child: const Icon(Icons.eco, color: Color(0xFF66BB6A), size: 22),
          ),
          Transform.translate(
            offset: const Offset(-6, -4),
            child: const Icon(Icons.local_florist, color: Colors.white, size: 16),
          ),
          Transform.rotate(
            angle: 0.3,
            child: const Icon(Icons.eco, color: Color(0xFF43A047), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: onClose ?? () => Navigator.pop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF5350), Color(0xFFD32F2F), Color(0xFFB71C1C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white, width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF5D0B0B),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 4),
              blurRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
