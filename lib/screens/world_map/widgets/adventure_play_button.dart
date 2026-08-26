import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/service_locator.dart';

class AdventurePlayButton extends StatelessWidget {
  final int levelNumber;
  final VoidCallback onPlay;

  const AdventurePlayButton({
    super.key,
    required this.levelNumber,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        ServiceLocator.instance.audioManager.playButtonClick();
        onPlay();
      },
      child: Container(
        width: double.infinity,
        height: 58,
        margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF72D32F),
              Color(0xFF4FA91D),
              Color(0xFF388012),
            ],
            stops: [0.0, 0.65, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFFC7F19C),
            width: 2.5,
          ),
          boxShadow: [
            // Deep 3D bottom bevel rim shadow
            const BoxShadow(
              color: Color(0xFF1E5207),
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
            // Outer ambient glow & shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            children: [
              // Top gloss highlight
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Button Text
              Center(
                child: Text(
                  'LEVEL $levelNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Color(0xFF1B4E08), blurRadius: 4, offset: Offset(0, 2.5)),
                      Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
