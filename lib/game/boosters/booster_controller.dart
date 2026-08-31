import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../board/board.dart';
import '../specials/special.dart';
import '../blast/blast_controller.dart';
import '../trail/match_result.dart';
import 'booster_use_state.dart';
import 'booster_use_result.dart';
import 'booster_config.dart';

class BoosterController extends ChangeNotifier {
  final BoardController boardController;
  final BlastController blastController;
  final Block? Function(String blockId) getBlock;
  final void Function(String blockId, Position newPos) onMoveBlock;
  final SpecialController specialController;

  BoosterInventory _inventory = BoosterConfig.getDefaultInventory();
  BoosterInventory get inventory => _inventory;

  BoosterUseState _state = BoosterUseState.idle;
  BoosterUseState get state => _state;

  BoosterType? _selectedBooster;
  BoosterType? get selectedBooster => _selectedBooster;

  BoosterController({
    required this.boardController,
    required this.blastController,
    required this.getBlock,
    required this.onMoveBlock,
    required this.specialController,
  });

  void loadInventory(BoosterInventory loaded) {
    _inventory = loaded;
    notifyListeners();
  }

  void selectBooster(BoosterType type) {
    if (_inventory.getQuantity(type) <= 0) return;
    if (_state == BoosterUseState.executing) return;

    _selectedBooster = type;
    _state = BoosterUseState.selecting;
    notifyListeners();

    // If it's a shuffle booster, it requires no target selection. Execute immediately.
    if (type == BoosterType.shuffle) {
      _executeShuffle();
    }
  }

  void cancelSelection() {
    if (_state == BoosterUseState.selecting) {
      _selectedBooster = null;
      _state = BoosterUseState.cancelled;
      notifyListeners();
      
      // Reset back to idle after a tick
      Future.microtask(() {
        _state = BoosterUseState.idle;
        notifyListeners();
      });
    }
  }

  Future<BoosterUseResult> executeTargetedBooster(Position targetPos) async {
    if (_state != BoosterUseState.selecting || _selectedBooster == null) {
      return BoosterUseResult(success: false, boosterType: BoosterType.hammer, error: "Invalid state");
    }

    final booster = _selectedBooster!;
    _state = BoosterUseState.executing;
    notifyListeners();

    final targetBlockId = boardController.getBlockId(targetPos);
    if (targetBlockId == null) {
      cancelSelection();
      return BoosterUseResult(success: false, boosterType: booster, error: "Empty cell");
    }
    
    final block = getBlock(targetBlockId);
    if (block == null || block.isLocked) {
      cancelSelection();
      return BoosterUseResult(success: false, boosterType: booster, error: "Invalid block");
    }

    final Map<String, Position> targetBlocks = {};

    if (booster == BoosterType.hammer) {
      targetBlocks[block.id] = block.position;
    } else if (booster == BoosterType.rowClear) {
      for (int c = 0; c < boardController.columns; c++) {
        final pos = Position(targetPos.row, c);
        final id = boardController.getBlockId(pos);
        if (id != null) {
          targetBlocks[id] = pos;
        }
      }
    } else if (booster == BoosterType.colorClear) {
      for (int r = 0; r < boardController.rows; r++) {
        for (int c = 0; c < boardController.columns; c++) {
          final pos = Position(r, c);
          final id = boardController.getBlockId(pos);
          if (id != null) {
            final b = getBlock(id);
            if (b != null && b.color == block.color) {
              targetBlocks[id] = pos;
            }
          }
        }
      }
    } else if (booster == BoosterType.areaBlast) {
      for (int r = (targetPos.row - 1).clamp(0, boardController.rows - 1); r <= (targetPos.row + 1).clamp(0, boardController.rows - 1); r++) {
        for (int c = (targetPos.column - 1).clamp(0, boardController.columns - 1); c <= (targetPos.column + 1).clamp(0, boardController.columns - 1); c++) {
          final pos = Position(r, c);
          final id = boardController.getBlockId(pos);
          if (id != null) {
            targetBlocks[id] = pos;
          }
        }
      }
    }

    // Check for special activations within targeted blocks
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

    // Consume the booster
    _inventory = _inventory.decrement(booster);
    
    // Convert to MatchResult to leverage existing BlastController destruction pipeline
    final matchResult = MatchResult(
      isValid: true,
      blockIds: targetBlocks.keys.toList(),
      positions: targetBlocks.values.toList(),
      length: targetBlocks.length,
      color: block.color,
      connectionType: ConnectionType.mega,
    );

    final blastResult = await blastController.processMatch(matchResult, source: DestructionSource.booster);

    _state = BoosterUseState.completed;
    _selectedBooster = null;
    notifyListeners();

    Future.microtask(() {
      _state = BoosterUseState.idle;
      notifyListeners();
    });

    return BoosterUseResult(
      success: true,
      boosterType: booster,
      consumed: true,
      affectedBlockIds: blastResult.destroyedBlockIds,
      affectedPositions: blastResult.destroyedPositions,
    );
  }

  Future<BoosterUseResult> _executeShuffle() async {
    _state = BoosterUseState.executing;
    notifyListeners();

    // Collect all movable blocks
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

    // Reassign positions
    for (int i = 0; i < blockIds.length; i++) {
      boardController.setBlockId(positions[i], blockIds[i]);
      onMoveBlock(blockIds[i], positions[i]);
    }

    _inventory = _inventory.decrement(BoosterType.shuffle);

    // Wait a short duration to let shuffle animation play
    await Future.delayed(const Duration(milliseconds: 500));

    _state = BoosterUseState.completed;
    _selectedBooster = null;
    notifyListeners();

    Future.microtask(() {
      _state = BoosterUseState.idle;
      notifyListeners();
    });

    return const BoosterUseResult(
      success: true,
      boosterType: BoosterType.shuffle,
      consumed: true,
    );
  }
}
