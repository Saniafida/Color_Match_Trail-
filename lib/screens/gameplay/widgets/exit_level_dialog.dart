import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';

class ExitLevelDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;

  const ExitLevelDialog({
    super.key,
    required this.onResume,
    required this.onExit,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onResume,
    required VoidCallback onExit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => ExitLevelDialog(
        onResume: onResume,
        onExit: onExit,
      ),
    );
  }

  @override
  State<ExitLevelDialog> createState() => _ExitLevelDialogState();
}

class _ExitLevelDialogState extends State<ExitLevelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleResume() {
    ServiceLocator.instance.audioManager.playButtonClick();
    Navigator.of(context).pop();
    widget.onResume();
  }

  void _handleExit() {
    ServiceLocator.instance.audioManager.playButtonClick();
    Navigator.of(context).pop();
    widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 320,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. Outer Mahogany / Walnut Wood Frame
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.fromLTRB(14, 28, 14, 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6D3C18),
                        Color(0xFF4A250B),
                        Color(0xFF2E1505),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 3.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 8),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Color(0x33FFD54F),
                        offset: Offset(0, 0),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Container(
                    // Inner Parchment / Cream Card Box
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFFDF5),
                          Color(0xFFFBF1DB),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE5D2A6),
                        width: 1.8,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),

                        // Broken Heart Graphic
                        Image.asset(
                          'assets/images/lose_screen/broken_heart.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.heart_broken_rounded,
                            color: Color(0xFFE53935),
                            size: 56,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Title text
                        const Text(
                          'Give Up This Level?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF3E200C),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black12,
                                offset: Offset(0, 1),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Warning message text
                        const Text(
                          'If you quit now, your level progress will be lost and you will lose 1 life!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7A4E24),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 1. Primary "KEEP PLAYING" (Glossy Green Button)
                        _buildActionButton(
                          text: 'KEEP PLAYING',
                          icon: Icons.play_arrow_rounded,
                          gradientColors: const [
                            Color(0xFF5CD82B),
                            Color(0xFF43B929),
                            Color(0xFF2E7D32),
                          ],
                          borderColor: const Color(0xFFAEF868),
                          shadowColor: const Color(0xFF1B5E20),
                          textColor: Colors.white,
                          onTap: _handleResume,
                        ),

                        const SizedBox(height: 10),

                        // 2. Secondary "QUIT LEVEL" (Glossy Red/Crimson Button)
                        _buildActionButton(
                          text: 'QUIT LEVEL',
                          icon: Icons.exit_to_app_rounded,
                          gradientColors: const [
                            Color(0xFFEF5350),
                            Color(0xFFE53935),
                            Color(0xFFC62828),
                          ],
                          borderColor: const Color(0xFFFF8A80),
                          shadowColor: const Color(0xFFB71C1C),
                          textColor: Colors.white,
                          onTap: _handleExit,
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Wooden Signboard Banner
                Positioned(
                  top: 6,
                  child: _buildTopBanner(),
                ),

                // Top-Right Glossy Circular Close (X) Button
                Positioned(
                  top: 14,
                  right: -2,
                  child: _buildCloseButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 7),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE082),
          width: 2.2,
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD54F), size: 20),
          SizedBox(width: 6),
          Text(
            'LEAVE LEVEL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              shadows: [
                Shadow(color: Color(0xFF331A0B), offset: Offset(1.5, 2), blurRadius: 1),
                Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: _handleResume,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF5350), Color(0xFFD32F2F), Color(0xFFB71C1C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF5D0B0B),
              offset: Offset(0, 2),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color shadowColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            const BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
