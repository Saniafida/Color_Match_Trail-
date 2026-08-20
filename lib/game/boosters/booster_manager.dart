import 'package:flutter/foundation.dart';
import '../../core/storage/storage.dart';
import '../../models/models.dart';
import '../board/board.dart';
import '../specials/special.dart';
import '../blast/blast_controller.dart';
import '../trail/match_result.dart';
import '../moves/move_controller.dart';
import '../moves/move_event.dart';
import '../level_result/level_result_system.dart';
import '../../core/services/service_locator.dart';
import 'booster_use_state.dart';
import 'booster_use_result.dart';
import 'booster_definition.dart';

class BoosterManager extends ChangeNotifier {
  final BoardController boardController;
  final BlastController blastController;
  final MoveController moveController;
  final LevelResultController levelResultController;
  final GameStorage storage;
  final Block? Function(String blockId) getBlock;
  final void Function(String blockId, Position newPos) onMoveBlock;
  final SpecialController specialController;

  BoosterInventory get inventory => ServiceLocator.instance.inventoryManager.inventory;

  BoosterUseState _state = BoosterUseState.idle;
  BoosterUseState get state => _state;

  BoosterDefinition? _selectedBoosterDef;
  BoosterDefinition? get selectedBoosterDef => _selectedBoosterDef;

  BoosterManager({
    required this.boardController,
    required this.blastController,
    required this.moveController,
    required this.levelResultController,
    required this.storage,
    required this.getBlock,
    required this.onMoveBlock,
    required this.specialController,
  }) {
    ServiceLocator.instance.inventoryManager.addListener(_onInventoryChanged);
  }

  @override
  void dispose() {
    ServiceLocator.instance.inventoryManager.removeListener(_onInventoryChanged);
    super.dispose();
  }

  void _onInventoryChanged() {
    notifyListeners();
  }

  Future<void> loadInventory() async {
    // Inventory is now pre-loaded globally by InventoryManager
    notifyListeners();
  }

  bool canActivateBooster(BoosterType type) {
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

  void selectBooster(BoosterType type) {
    if (!canActivateBooster(type)) return;
    if (_state == BoosterUseState.executing) return;

    final def = BoosterDefinition.registry[type];
    if (def == null) return;

    _selectedBoosterDef = def;
    _state = BoosterUseState.selecting;
    notifyListeners();

    if (def.activationStyle == BoosterActivationStyle.instant) {
      _executeInstantBooster(def);
    }
  }

  void cancelSelection() {
    if (_state == BoosterUseState.selecting) {
      _selectedBoosterDef = null;
      _state = BoosterUseState.cancelled;
      notifyListeners();
      
      Future.microtask(() {
        _state = BoosterUseState.idle;
        notifyListeners();
      });
    }
  }

  Future<void> _executeInstantBooster(BoosterDefinition def) async {
    _state = BoosterUseState.executing;
    notifyListeners();

    if (def.type == BoosterType.shuffle) {
      await _executeShuffle();
    } else if (def.type == BoosterType.extraMoves) {
      await _executeExtraMoves();
    }

    // Consume inventory AFTER successful execution
    await ServiceLocator.instance.inventoryManager.consumeBooster(def.type, 1);

    _state = BoosterUseState.completed;
    _selectedBoosterDef = null;
    notifyListeners();

    Future.microtask(() {
      _state = BoosterUseState.idle;
      notifyListeners();
    });
  }

  Future<BoosterUseResult> executeTargetedBooster(Position targetPos) async {
    if (_state != BoosterUseState.selecting || _selectedBoosterDef == null) {
      return const BoosterUseResult(success: false, boosterType: BoosterType.hammer, error: "Invalid state");
    }

    final def = _selectedBoosterDef!;
    
    final targetBlockId = boardController.getBlockId(targetPos);
    if (targetBlockId == null) {
      cancelSelection();
      return BoosterUseResult(success: false, boosterType: def.type, error: "Empty cell");
    }
    
    final block = getBlock(targetBlockId);
    if (block == null || block.isLocked) {
      cancelSelection();
      return BoosterUseResult(success: false, boosterType: def.type, error: "Invalid block");
    }

    _state = BoosterUseState.executing;
    notifyListeners();

    Set<String> affectedIds = {};
    Set<Position> affectedPositions = {};

    if (def.type == BoosterType.hammer) {
      affectedIds.add(block.id);
      affectedPositions.add(block.position);
    } else if (def.type == BoosterType.rowClear) {
      for (int c = 0; c < boardController.columns; c++) {
        final pos = Position(targetPos.row, c);
        final id = boardController.getBlockId(pos);
        if (id != null) {
          affectedIds.add(id);
          affectedPositions.add(pos);
        }
      }
    } else if (def.type == BoosterType.colorClear) {
      for (int r = 0; r < boardController.rows; r++) {
        for (int c = 0; c < boardController.columns; c++) {
          final pos = Position(r, c);
          final id = boardController.getBlockId(pos);
          if (id != null) {
            final b = getBlock(id);
            if (b != null && b.color == block.color) {
              affectedIds.add(id);
              affectedPositions.add(pos);
            }
          }
        }
      }
    }

    // Special checks
    final Set<String> specialExpandedIds = {};
    final Set<Position> specialExpandedPos = {};
    
    for (final id in affectedIds) {
      final b = getBlock(id);
      if (b != null && b.specialType != SpecialBlockType.none) {
        final specialResult = specialController.activateSpecial(
          SpecialActivationRequest(
            blockId: b.id,
            position: b.position,
            type: b.specialType,
            color: b.color,
          )
        );
        specialExpandedIds.addAll(specialResult.targetBlockIds);
        specialExpandedPos.addAll(specialResult.targetPositions);
      }
    }

    affectedIds.addAll(specialExpandedIds);
    affectedPositions.addAll(specialExpandedPos);

    final matchResult = MatchResult(
      isValid: true,
      blockIds: affectedIds.toList(),
      positions: affectedPositions.toList(),
      length: affectedIds.length,
      color: block.color,
    );

    final blastResult = await blastController.processMatch(matchResult, source: DestructionSource.booster);

    // Consume the booster ONLY AFTER SUCCESS
    await ServiceLocator.instance.inventoryManager.consumeBooster(def.type, 1);

    if (def.moveCost > 0) {
      moveController.consumeMove(source: MoveSource.booster);
    }

    _state = BoosterUseState.completed;
    _selectedBoosterDef = null;
    notifyListeners();

    Future.microtask(() {
      _state = BoosterUseState.idle;
      notifyListeners();
    });

    return BoosterUseResult(
      success: true,
      boosterType: def.type,
      consumed: true,
      affectedBlockIds: blastResult.destroyedBlockIds,
      affectedPositions: blastResult.destroyedPositions,
    );
  }

  Future<void> _executeShuffle() async {
    final List<String> blockIds = [];
    final List<Position> positions = [];

    for (int r = 0; r < boardController.rows; r++) {
      for (int c = 0; c < boardController.columns; c++) {
        final pos = Position(r, c);
        final id = boardController.getBlockId(pos);
        if (id != null) {
          blockIds.add(id);
          positions.add(pos);
        }
      }
    }

    blockIds.shuffle();

    for (int i = 0; i < blockIds.length; i++) {
      boardController.setBlockId(positions[i], blockIds[i]);
      onMoveBlock(blockIds[i], positions[i]);
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _executeExtraMoves() async {
    moveController.addMoves(5);
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
