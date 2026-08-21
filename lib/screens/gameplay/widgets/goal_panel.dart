import 'package:flutter/material.dart';
import '../../../game/goals/goal_controller.dart';
import '../../../game/goals/goal_state.dart';
import '../../../models/models.dart';
import '../../../game/blocks/block_color_mapper.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B140E).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC7A774).withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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

    Widget iconWidget;

    if (def.type == GoalType.clearColor && def.color != null) {
      final style = BlockColorMapper.getStyle(def.color!);
      iconWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [style.highlight, style.main, style.shadow],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            style.normalIcon,
            size: 16,
            color: style.iconHighlight.withValues(alpha: 0.9),
          ),
        ),
      );
    } else if (def.type == GoalType.createSpecial) {
      iconWidget = const Icon(Icons.rocket_launch_rounded, color: Colors.amberAccent, size: 24);
    } else {
      iconWidget = const Icon(Icons.star_rounded, color: Colors.amber, size: 24);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted ? Colors.greenAccent : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24)
          else
            iconWidget,
          const SizedBox(width: 8),
          Text(
            isCompleted ? 'DONE' : '$progress / $target',
            style: TextStyle(
              color: isCompleted ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
