import 'package:flutter/material.dart';
import '../../../game/score/score_controller.dart';
import '../../../game/moves/move_controller.dart';
import '../../../core/services/timer/timer_controller.dart';
import 'level_header.dart';
import 'score_display.dart';
import 'moves_display.dart';
import 'timer_display.dart';

class GameplayHud extends StatelessWidget {
  final String levelId;
  final VoidCallback onPause;
  final ScoreController scoreController;
  final MoveController moveController;
  final TimerController timerController;
  final bool hasTimeLimit;

  const GameplayHud({
    super.key,
    required this.levelId,
    required this.onPause,
    required this.scoreController,
    required this.moveController,
    required this.timerController,
    required this.hasTimeLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          LevelHeader(levelId: levelId, onPause: onPause),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasTimeLimit)
                TimerDisplay(timerController: timerController)
              else
                MovesDisplay(moveController: moveController),
              
              ScoreDisplay(scoreController: scoreController),
            ],
          ),
        ],
      ),
    );
  }
}
