import 'package:flutter/material.dart';

class PlayButton extends StatefulWidget {
  final int currentLevelNumber;
  final bool isCampaignCompleted;
  final VoidCallback onPlay;

  const PlayButton({
    super.key,
    required this.currentLevelNumber,
    this.isCampaignCompleted = false,
    required this.onPlay,
  });

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = 'PLAY';
    if (widget.isCampaignCompleted) {
      buttonText = 'ALL CLEAR 🎉';
    } else if (widget.currentLevelNumber > 1) {
      buttonText = 'CONTINUE';
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2C3E50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 8,
          shadowColor: Colors.black54,
        ),
        onPressed: widget.onPlay,
        child: Column(
          children: [
            Text(
              buttonText,
              style: TextStyle(
                fontSize: widget.isCampaignCompleted ? 24 : 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isCampaignCompleted
                  ? 'Replay Any Level'
                  : 'LEVEL ${widget.currentLevelNumber}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
