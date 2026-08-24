import 'package:flutter/material.dart';

class WoodSignHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double height;

  const WoodSignHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Wood Signboard
          Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB57C3E),
                  Color(0xFF8B5A2B),
                  Color(0xFF6B4226),
                  Color(0xFF533118),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD54F),
                width: 2.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF331A0B),
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black45,
                  offset: Offset(0, 6),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Small gold rivets on wood sign
                _buildRivet(),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFFDE7),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Color(0xFF3E200C),
                        offset: Offset(1.5, 2.5),
                        blurRadius: 1,
                      ),
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _buildRivet(),
              ],
            ),
          ),

          // Left Back Button
          if (onBack != null)
            Positioned(
              left: 0,
              child: _buildCircleWoodButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack!,
              ),
            ),

          // Right Trailing
          if (trailing != null)
            Positioned(
              right: 0,
              child: trailing!,
            ),
        ],
      ),
    );
  }

  Widget _buildRivet() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFB300), Color(0xFF8D6E63)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleWoodButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFB57C3E), Color(0xFF795548), Color(0xFF4E342E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: const Color(0xFFFFD54F),
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF331A0B),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
          shadows: const [
            Shadow(color: Colors.black45, offset: Offset(1, 2), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
