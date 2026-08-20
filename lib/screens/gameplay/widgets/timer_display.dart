import 'package:flutter/material.dart';
import '../../../core/services/timer/timer_controller.dart';

class TimerDisplay extends StatelessWidget {
  final TimerController timerController;

  const TimerDisplay({
    super.key,
    required this.timerController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: timerController,
      builder: (context, child) {
        final state = timerController.state;
        final isLow = state.remainingSeconds <= 10;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLow 
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: isLow ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Column(
            children: [
              const Text(
                'TIME',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${state.remainingSeconds}s',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isLow ? Colors.redAccent : Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
