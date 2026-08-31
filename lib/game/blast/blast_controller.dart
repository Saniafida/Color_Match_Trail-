import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../board/board.dart';
import '../trail/match_result.dart';
import '../specials/special.dart';
import 'blast_result.dart';

typedef BlockLookup = Block? Function(String blockId);
typedef BlockUpdater = void Function(Block block);
typedef BlockRemover = void Function(String blockId);

class BlastController extends ChangeNotifier {
  final BoardController boardController;
  final BlockLookup getBlock;
  final BlockUpdater onUpdateBlock;
  final BlockRemover onRemoveBlock;
  final SpecialController specialController;

  bool _isBlasting = false;
  bool get isBlasting => _isBlasting;

  final StreamController<BlastResult> _blastEventController = StreamController<BlastResult>.broadcast(sync: true);
  Stream<BlastResult> get onBlast => _blastEventController.stream;

  BlastController({
    required this.boardController,
    required this.getBlock,
    required this.onUpdateBlock,
    required this.onRemoveBlock,
    required this.specialController,
  });

  Future<BlastResult> processMatch(MatchResult match, {DestructionSource source = DestructionSource.playerMatch}) async {
    if (_isBlasting) {
      return const BlastResult(success: false);
    }
    if (!match.isValid || match.blockIds.isEmpty) {
      return const BlastResult(success: false);
    }

    // Verify all blocks still exist and are valid for destruction
    if (source == DestructionSource.playerMatch) {
      for (int i = 0; i < match.blockIds.length; i++) {
        final id = match.blockIds[i];
        final block = getBlock(id);
        if (block == null || block.isLocked || block.isBeingDestroyed) {
          return const BlastResult(success: false);
        }
        if (i < match.positions.length) {
          final pos = match.positions[i];
          final boardId = boardController.getBlockId(pos);
          if (boardId != id) return const BlastResult(success: false);
        }
      }
    }

    // Collect valid blocks and their actual board positions
    final Map<String, Position> validatedBlocks = {};
    for (int i = 0; i < match.blockIds.length; i++) {
      final id = match.blockIds[i];
      final block = getBlock(id);
      if (block == null || block.isLocked || block.isBeingDestroyed) {
        continue;
      }

      Position? pos;
      if (i < match.positions.length && boardController.getBlockId(match.positions[i]) == id) {
        pos = match.positions[i];
      } else {
        final blockPos = block.position;
        if (boardController.getBlockId(blockPos) == id) {
          pos = blockPos;
        } else {
          for (int r = 0; r < boardController.rows; r++) {
            for (int c = 0; c < boardController.columns; c++) {
              final p = Position(r, c);
              if (boardController.getBlockId(p) == id) {
                pos = p;
                break;
              }
            }
            if (pos != null) break;
          }
        }
      }

      if (pos != null) {
        validatedBlocks[id] = pos;
      }
    }

    if (validatedBlocks.isEmpty) {
      return const BlastResult(success: false);
    }

    // Determine special creation (if applicable)
    String? specialCreationBlockId;
    SpecialBlockType specialCreationType = SpecialBlockType.none;
    
    if (match.specialCreationHint != SpecialCreationType.none) {
      final middleIndex = match.length ~/ 2;
      if (middleIndex < match.blockIds.length) {
        specialCreationBlockId = match.blockIds[middleIndex];
      }
      
      switch (match.specialCreationHint) {
        case SpecialCreationType.lineBlast:
          specialCreationType = SpecialBlockType.horizontalLine;
          break;
        case SpecialCreationType.bomb:
          specialCreationType = SpecialBlockType.bomb;
          break;
        case SpecialCreationType.colorBomb:
          specialCreationType = SpecialBlockType.colorSpecial;
          break;
        default:
          break;
      }
    }

    final Map<String, Position> targetBlocks = Map.from(validatedBlocks);
    if (specialCreationBlockId != null) {
      targetBlocks.remove(specialCreationBlockId);
    }
    
    // Check for special activations and chain reactions
    for (final entry in validatedBlocks.entries) {
      if (entry.key == specialCreationBlockId) continue;
      
      final block = getBlock(entry.key);
      if (block != null && block.specialType != SpecialBlockType.none) {
        final result = specialController.activateSpecial(
          SpecialActivationRequest(
            blockId: block.id,
            position: entry.value,
            type: block.specialType,
            color: block.color,
          )
        );
        for (int j = 0; j < result.targetBlockIds.length; j++) {
          final tId = result.targetBlockIds[j];
          final tPos = result.targetPositions[j];
          // Protect newly created special from being destroyed instantly by a chain reaction in the same turn
          if (tId != specialCreationBlockId) {
            targetBlocks[tId] = tPos;
          }
        }
      }
    }

    // Play blast
    _isBlasting = true;
    notifyListeners();

    BlastIntensity intensity = match.connectionType == ConnectionType.mega ? BlastIntensity.mega : BlastIntensity.normal;
    Duration duration = const Duration(milliseconds: 400);
    if (targetBlocks.length > match.length) {
      intensity = BlastIntensity.mega; // Upgrade intensity if specials triggered
    }

    // Phase 1: Mark as being destroyed with sequential stagger
    final targetList = targetBlocks.keys.toList();
    final staggerMs = (targetList.length > 1) ? 20 : 0;
    final totalStaggerDuration = Duration(milliseconds: staggerMs * (targetList.length - 1));

    for (int i = 0; i < targetList.length; i++) {
      final id = targetList[i];
      final block = getBlock(id);
      if (block != null) {
        onUpdateBlock(block.copyWith(
          isBeingDestroyed: true,
          isSelected: false,
        ));
      }
      if (staggerMs > 0 && i < targetList.length - 1) {
        await Future.delayed(Duration(milliseconds: staggerMs));
      }
    }
    
    // Create special
    if (specialCreationBlockId != null && specialCreationType != SpecialBlockType.none) {
      final block = getBlock(specialCreationBlockId);
      if (block != null) {
        onUpdateBlock(block.copyWith(
          specialType: specialCreationType,
          isSelected: false,
        ));
      }
    }

    final remainingDelay = duration - totalStaggerDuration;
    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

    // Phase 2: Physically remove
    for (final entry in targetBlocks.entries) {
      final pos = entry.value;
      final id = entry.key;
      if (boardController.getBlockId(pos) == id) {
        boardController.clearCell(pos);
      } else {
        for (int r = 0; r < boardController.rows; r++) {
          for (int c = 0; c < boardController.columns; c++) {
            final p = Position(r, c);
            if (boardController.getBlockId(p) == id) {
              boardController.clearCell(p);
              break;
            }
          }
        }
      }
      onRemoveBlock(id);
    }

    _isBlasting = false;
    notifyListeners();
    
    final result = BlastResult(
      success: true,
      destroyedBlockIds: targetBlocks.keys.toList(),
      destroyedPositions: targetBlocks.values.toList(),
      destroyedCount: targetBlocks.length,
      color: match.color,
      intensity: intensity,
      duration: duration,
      specialCreationHint: match.specialCreationHint,
      isClosedLoop: match.isClosedLoop,
      source: source,
    );

    _blastEventController.add(result);

    return result;
  }
}
