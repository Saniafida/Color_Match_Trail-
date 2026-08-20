import '../goals/goal_controller.dart';
import '../../models/level_rules.dart';

class WinConditionController {
  final GoalController goalController;
  final WinRule winRule;

  const WinConditionController({
    required this.goalController,
    required this.winRule,
  });

  bool get isWinConditionMet {
    switch (winRule) {
      case WinRule.allRequiredGoalsCompleted:
        return goalController.allRequiredGoalsCompleted;
    }
  }
}
