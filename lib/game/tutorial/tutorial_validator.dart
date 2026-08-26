import 'tutorial_manager.dart';
import '../../models/models.dart';
import '../board/board.dart';

class TutorialValidator {
  static bool canStartDrag(TutorialManager tutorialManager, Position startPos, BoardController boardController) {
    if (!tutorialManager.isActive) return true;
    
    final step = tutorialManager.currentStep;
    if (step == null) return true;

    if (step.requiredAction == 'connect') {
      if (step.targetType == 'board') {
        // If there's a specific targetId like "0,0", validate it.
        // Otherwise, allow dragging but maybe check color matching in trail logic.
        return true; 
      }
      return false; // Not a board connect action
    }

    // If waiting for continue/tap, don't allow board interaction
    return false;
  }

  static bool canUseBooster(TutorialManager tutorialManager, BoosterType boosterType) {
    if (!tutorialManager.isActive) return true;

    final step = tutorialManager.currentStep;
    if (step == null) return true;

    if (step.requiredAction == 'use_booster') {
      return step.targetId == boosterType.name;
    }

    return true;
  }
}
