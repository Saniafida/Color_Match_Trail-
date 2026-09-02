import 'package:flutter/material.dart';
import '../../../game/score/score_controller.dart';
import '../../../game/moves/move_controller.dart';
import '../../../game/goals/goal_controller.dart';
import '../../../core/services/timer/timer_controller.dart';
import 'level_header.dart';
import 'score_display.dart';
import 'moves_display.dart';
import 'timer_display.dart';
import 'goal_panel.dart';

class GameplayHud extends StatelessWidget {
  final String levelId;
  final VoidCallback onPause;
  final VoidCallback? onSettings;
  final VoidCallback? onBack;
  final ScoreController scoreController;
  final MoveController moveController;
  final TimerController timerController;
  final GoalController goalController;
  final bool hasTimeLimit;
  final List<int> starThresholds;

  const GameplayHud({
    super.key,
    required this.levelId,
    required this.onPause,
    this.onSettings,
    this.onBack,
    required this.scoreController,
    required this.moveController,
    required this.timerController,
    required this.goalController,
    required this.hasTimeLimit,
    this.starThresholds = const [1000, 2000, 3000],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Bar: Blue Back Button, Level Plaque, Hearts, Coins, Gems, Pause, Settings
          LevelHeader(
            levelId: levelId,
            onPause: onPause,
            onSettings: onSettings,
            onBack: onBack,
          ),

          const SizedBox(height: 10),

          // 2. Middle HUD Row: Moves (Left), Goal Signboard (Center), Score (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Moves or Timer Signboard (Compact)
              if (hasTimeLimit)
                TimerDisplay(timerController: timerController)
              else
                MovesDisplay(moveController: moveController),

              const SizedBox(width: 5),

              // Goal Signboard (Expanded & fully responsive with FittedBox)
              Expanded(
                child: GoalPanel(goalController: goalController),
              ),

              const SizedBox(width: 5),

              // Score Signboard with 3 Stars (Compact)
              ScoreDisplay(
                scoreController: scoreController,
                starThresholds: starThresholds,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
