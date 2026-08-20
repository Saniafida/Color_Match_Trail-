import 'package:flutter/material.dart';
import '../../../game/goals/goal_controller.dart';
import '../../../game/goals/goal_state.dart';
import '../../../models/models.dart';

class GoalPanel extends StatelessWidget {
  final GoalController goalController;

  const GoalPanel({
    super.key,
    required this.goalController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: goalController,
      builder: (context, child) {
        final stateList = goalController.states;
        if (stateList.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: stateList.map((goalState) {
                return _buildGoalItem(goalState);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalItem(GoalState goalState) {
    final def = goalController.getDefinition(goalState.goalId);
    final progress = goalState.currentAmount;
    final target = goalState.targetAmount;
    final isCompleted = goalState.completed;

    Color iconColor = Colors.white;
    IconData icon = Icons.star;

    if (def.type == GoalType.clearColor && def.color != null) {
      switch (def.color!) {
        case BlockColor.red:
          iconColor = Colors.red;
          icon = Icons.square_rounded;
          break;
        case BlockColor.blue:
          iconColor = Colors.blue;
          icon = Icons.square_rounded;
          break;
        case BlockColor.green:
          iconColor = Colors.green;
          icon = Icons.square_rounded;
          break;
        case BlockColor.yellow:
          iconColor = Colors.yellow;
          icon = Icons.square_rounded;
          break;
        case BlockColor.purple:
          iconColor = Colors.purple;
          icon = Icons.square_rounded;
          break;
      }
    } else if (def.type == GoalType.createSpecial) {
      iconColor = Colors.amber;
      icon = Icons.flare;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCompleted ? Icons.check_circle : icon, color: isCompleted ? Colors.green : iconColor, size: 24),
          const SizedBox(width: 8),
          Text(
            isCompleted ? 'DONE' : '$progress / $target',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
