import '../../models/booster.dart';
import '../board/board.dart';
import '../level_result/level_result_system.dart';
import '../blast/blast_controller.dart';
import 'booster_definition.dart';
import '../../core/services/service_locator.dart';
import '../../models/models.dart';

class BoosterValidator {
  static bool canActivateBooster({
    required BoosterType type,
    required LevelResultController levelResultController,
    required BlastController blastController,
  }) {
    final inventory = ServiceLocator.instance.inventoryManager.inventory;
    
    // Inventory check
    if (inventory.getQuantity(type) <= 0) return false;

    // Game state check
    if (levelResultController.status != GameStatus.playing) return false;
    
    // Resolution check
    if (blastController.isBlasting) return false;

    // Level type checks
    final def = BoosterDefinition.registry[type];
    if (def == null) return false;

    final levelDef = levelResultController.levelDefinition;
    if (levelDef.movesLimit != null && !def.allowedInMoveLevels) return false;
    if (levelDef.timeLimit != null && !def.allowedInTimeLevels) return false;

    return true;
  }

  static bool isTargetValid({
    required Position targetPos,
    required BoardController boardController,
    required Block? Function(String) getBlock,
  }) {
    final targetBlockId = boardController.getBlockId(targetPos);
    if (targetBlockId == null) return false;
    
    final block = getBlock(targetBlockId);
    if (block == null || block.isLocked) return false;
    
    return true;
  }
}
