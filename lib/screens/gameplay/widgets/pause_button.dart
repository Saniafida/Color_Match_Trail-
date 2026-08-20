import 'package:flutter/material.dart';

class PauseButton extends StatelessWidget {
  final VoidCallback onPause;

  const PauseButton({super.key, required this.onPause});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.pause, color: Colors.white, size: 28),
      onPressed: onPause,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
