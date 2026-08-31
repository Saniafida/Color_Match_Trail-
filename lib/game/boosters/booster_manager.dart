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
import '../achievements/achievement_event.dart';
import 'booster_use_state.dart';
import 'booster_use_result.dart';
import 'booster_definition.dart';
import 'booster_validator.dart';
import 'booster_combination_definition.dart';
import 'booster_combination_manager.dart';
import 'effects/hammer_effect.dart';
import 'effects/color_bomb_effect.dart';
import 'effects/shuffle_effect.dart';
import 'effects/extra_moves_effect.dart';
import 'effects/line_blast_effect.dart';
import 'effects/area_blast_effect.dart';

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

  BoosterDefinition? _secondBoosterDef;
  BoosterDefinition? get secondBoosterDef => _secondBoosterDef;

  BoosterCombinationDefinition? _activeCombination;
  BoosterCombinationDefinition? get activeCombination => _activeCombination;

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
    levelResultController.addListener(_onGameStateChanged);
    blastController.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    ServiceLocator.instance.inventoryManager.removeListener(_onInventoryChanged);
    levelResultController.removeListener(_onGameStateChanged);
    blastController.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onInventoryChanged() {
    notifyListeners();
  }

  void _onGameStateChanged() {
    notifyListeners();
  }

  Future<void> loadInventory() async {
    notifyListeners();
  }

  bool canActivateBooster(BoosterType type) {
    return BoosterValidator.canActivateBooster(
      type: type,
      levelResultController: levelResultController,
      blastController: blastController,
    );
  }

  void selectBooster(BoosterType type) {
    if (!canActivateBooster(type)) return;
    if (_state == BoosterUseState.executing) return;

    final def = BoosterDefinition.registry[type];
    if (def == null) return;

    if (_state == BoosterUseState.selectingCombo) {
      if (_selectedBoosterDef?.type == type || _secondBoosterDef?.type == type) {
        cancelSelection();
        return;
      } else {
        cancelSelection();
      }
    }

    if (_state == BoosterUseState.selecting) {
      if (_selectedBoosterDef?.type == type) {
        cancelSelection();
        return;
      }

      // Check if they can be combined
      final combo = BoosterCombinationDefinition.getCombination(_selectedBoosterDef!.type, type);
      if (combo != null) {
        // Can we afford the second one?
        // Note: if a user clicks the same type twice, we need 2 in inventory.
        final neededForA = combo.boosterA == type ? 1 : 0;
        final neededForB = combo.boosterB == type ? 1 : 0;
        final totalNeeded = neededForA + neededForB;
        if (inventory.getQuantity(type) < totalNeeded) {
          // Can't afford combo, swap selection
          _selectedBoosterDef = def;
          _activeCombination = null;
          _secondBoosterDef = null;
          notifyListeners();
          if (def.activationStyle == BoosterActivationStyle.instant) {
            _executeInstantBooster(def);
          }
          return;
        }

        _secondBoosterDef = def;
        _activeCombination = combo;
        _state = BoosterUseState.selectingCombo;
        notifyListeners();
        return;
      } else {
        // Cannot combine, swap selection
        _selectedBoosterDef = def;
        _activeCombination = null;
        _secondBoosterDef = null;
        notifyListeners();
        if (def.activationStyle == BoosterActivationStyle.instant) {
          _executeInstantBooster(def);
        }
        return;
      }
    }

    _selectedBoosterDef = def;
    _state = BoosterUseState.selecting;
    notifyListeners();

    if (def.activationStyle == BoosterActivationStyle.instant) {
      _executeInstantBooster(def);
    }
  }

  void cancelSelection() {
    if (_state == BoosterUseState.selecting || _state == BoosterUseState.selectingCombo) {
      _selectedBoosterDef = null;
      _secondBoosterDef = null;
      _activeCombination = null;
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
      await ShuffleEffect.execute(boardController, onMoveBlock);
    } else if (def.type == BoosterType.extraMoves) {
      await ExtraMovesEffect.execute(moveController);
    }

    await ServiceLocator.instance.inventoryManager.consumeBooster(def.type, 1);

    _state = BoosterUseState.completed;
    _selectedBoosterDef = null;
    
    final boosterEvent = BoosterUsedEvent(def.type.name);
    ServiceLocator.instance.achievementManager.processEvent(boosterEvent);
    ServiceLocator.instance.milestoneManager.processEvent(boosterEvent);
    
    notifyListeners();

    Future.microtask(() {
      _state = BoosterUseState.idle;
      notifyListeners();
    });
  }

  Future<BoosterUseResult> executeTargetedBooster(Position targetPos) async {
    if ((_state != BoosterUseState.selecting && _state != BoosterUseState.selectingCombo) || _selectedBoosterDef == null) {
      return const BoosterUseResult(success: false, boosterType: BoosterType.hammer, error: "Invalid state");
    }

    final isCombo = _state == BoosterUseState.selectingCombo && _activeCombination != null;
    final def = _selectedBoosterDef!;
    final secondDef = _secondBoosterDef;
    final combo = _activeCombination;
    
    if (!BoosterValidator.isTargetValid(
      targetPos: targetPos,
      boardController: boardController,
      getBlock: getBlock,
    )) {
      cancelSelection();
      return BoosterUseResult(success: false, boosterType: def.type, error: "Invalid target");
    }

    _state = BoosterUseState.executing;
    notifyListeners();

    Set<Position> affectedPositions = {};

    if (isCombo) {
      affectedPositions = BoosterCombinationManager.executeCombinationEffect(
        combo!.resultEffect,
        targetPos,
        boardController,
        getBlock,
      );
    } else {
      switch (def.type) {
        case BoosterType.hammer:
          affectedPositions = HammerEffect.getAffectedPositions(targetPos, boardController, getBlock);
          break;
        case BoosterType.rowClear:
          affectedPositions = LineBlastEffect.getAffectedPositions(targetPos, boardController);
          break;
        case BoosterType.colorClear:
          affectedPositions = ColorBombEffect.getAffectedPositions(targetPos, boardController, getBlock);
          break;
        case BoosterType.areaBlast:
          affectedPositions = AreaBlastEffect.getAffectedPositions(targetPos, boardController);
          break;
        default:
          break;
      }
    }

    final Map<String, Position> targetBlocks = {};
    for (final pos in affectedPositions) {
      final id = boardController.getBlockId(pos);
      if (id != null) {
        final b = getBlock(id);
        if (b != null && !b.isLocked && !b.isBeingDestroyed) {
          targetBlocks[id] = pos;
        }
      }
    }

    if (targetBlocks.isEmpty) {
      cancelSelection();
      return BoosterUseResult(success: false, boosterType: def.type, error: "No blocks affected");
    }

    // Special block expansion
    final List<MapEntry<String, Position>> initialSpecials = targetBlocks.entries.toList();
    for (final entry in initialSpecials) {
      final b = getBlock(entry.key);
      if (b != null && b.specialType != SpecialBlockType.none) {
        final specialResult = specialController.activateSpecial(
          SpecialActivationRequest(
            blockId: b.id,
            position: entry.value,
            type: b.specialType,
            color: b.color,
          ),
        );
        for (int i = 0; i < specialResult.targetBlockIds.length; i++) {
          final sId = specialResult.targetBlockIds[i];
          final sPos = specialResult.targetPositions[i];
          targetBlocks[sId] = sPos;
        }
      }
    }
    
    final targetBlockIdForColor = boardController.getBlockId(targetPos);
    final targetBlockColor = targetBlockIdForColor != null ? getBlock(targetBlockIdForColor)?.color : null;

    final matchResult = MatchResult(
      isValid: true,
      blockIds: targetBlocks.keys.toList(),
      positions: targetBlocks.values.toList(),
      length: targetBlocks.length,
      color: targetBlockColor,
      connectionType: ConnectionType.mega,
    );

    final blastResult = await blastController.processMatch(matchResult, source: DestructionSource.booster);

    // Consume inventory
    if (isCombo) {
      await ServiceLocator.instance.inventoryManager.consumeBooster(def.type, 1);
      await ServiceLocator.instance.inventoryManager.consumeBooster(secondDef!.type, 1);
      
      final boosterEvent1 = BoosterUsedEvent(def.type.name);
      final boosterEvent2 = BoosterUsedEvent(secondDef.type.name);
      ServiceLocator.instance.achievementManager.processEvent(boosterEvent1);
      ServiceLocator.instance.achievementManager.processEvent(boosterEvent2);
      ServiceLocator.instance.milestoneManager.processEvent(boosterEvent1);
      ServiceLocator.instance.milestoneManager.processEvent(boosterEvent2);
    } else {
      await ServiceLocator.instance.inventoryManager.consumeBooster(def.type, 1);
      
      final boosterEvent = BoosterUsedEvent(def.type.name);
      ServiceLocator.instance.achievementManager.processEvent(boosterEvent);
      ServiceLocator.instance.milestoneManager.processEvent(boosterEvent);
    }

    if (def.moveCost > 0) {
      moveController.consumeMove(source: MoveSource.booster);
    }

    _state = BoosterUseState.completed;
    _selectedBoosterDef = null;
    _secondBoosterDef = null;
    _activeCombination = null;
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
      blastResult: blastResult,
    );
  }
}
