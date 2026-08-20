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

    Set<String> affectedIds = {};
    Set<Position> affectedPositions = {};

    if (booster == BoosterType.hammer) {
      affectedIds.add(block.id);
      affectedPositions.add(block.position);
    } else if (booster == BoosterType.rowClear) {
      for (int c = 0; c < boardController.columns; c++) {
        final pos = Position(targetPos.row, c);
        final id = boardController.getBlockId(pos);
        if (id != null) {
          affectedIds.add(id);
          affectedPositions.add(pos);
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
              affectedIds.add(id);
              affectedPositions.add(pos);
            }
          }
        }
      }
    }

    // Check for special activations within targeted blocks
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

    // Consume the booster
    _inventory = _inventory.decrement(booster);
    
    // Convert to MatchResult to leverage existing BlastController destruction pipeline
    // It's not a real match, but it holds the targets nicely.
    final matchResult = MatchResult(
      isValid: true,
      blockIds: affectedIds.toList(),
      positions: affectedPositions.toList(),
      length: affectedIds.length,
      color: block.color,
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
