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
    for (int i = 0; i < match.blockIds.length; i++) {
      final id = match.blockIds[i];
      final pos = match.positions[i];
      
      final boardId = boardController.getBlockId(pos);
      if (boardId != id) return const BlastResult(success: false);
      
      final block = getBlock(id);
      if (block == null || block.isLocked || block.isBeingDestroyed) {
        return const BlastResult(success: false);
      }
    }

    // Determine creation
    String? specialCreationBlockId;
    SpecialBlockType specialCreationType = SpecialBlockType.none;
    
    if (match.specialCreationHint != SpecialCreationType.none) {
      final middleIndex = match.length ~/ 2;
      specialCreationBlockId = match.blockIds[middleIndex];
      
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

    final Set<String> targetBlockIds = {};
    final Set<Position> targetPositions = {};
    
    for (int i = 0; i < match.blockIds.length; i++) {
      if (match.blockIds[i] == specialCreationBlockId) continue;
      targetBlockIds.add(match.blockIds[i]);
      targetPositions.add(match.positions[i]);
    }
    
    // Check for special activations
    for (int i = 0; i < match.blockIds.length; i++) {
      if (match.blockIds[i] == specialCreationBlockId) continue;
      
      final block = getBlock(match.blockIds[i]);
      if (block != null && block.specialType != SpecialBlockType.none) {
        final result = specialController.activateSpecial(
          SpecialActivationRequest(
            blockId: block.id,
            position: block.position,
            type: block.specialType,
            color: block.color,
          )
        );
        for (int j = 0; j < result.targetBlockIds.length; j++) {
          final tId = result.targetBlockIds[j];
          final tPos = result.targetPositions[j];
          // Protect newly created special from being destroyed instantly by a chain reaction in the same turn
          if (tId != specialCreationBlockId) {
            targetBlockIds.add(tId);
            targetPositions.add(tPos);
          }
        }
      }
    }

    // Play blast
    _isBlasting = true;
    notifyListeners();

    BlastIntensity intensity = match.connectionType == ConnectionType.mega ? BlastIntensity.mega : BlastIntensity.normal;
    Duration duration = const Duration(milliseconds: 400);
    if (targetBlockIds.length > match.length) {
      intensity = BlastIntensity.mega; // Upgrade intensity if specials triggered
    }

    // Phase 1: Mark as being destroyed with sequential stagger
    final targetList = targetBlockIds.toList();
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
    for (final pos in targetPositions) {
      final id = boardController.getBlockId(pos);
      if (id != null && targetBlockIds.contains(id)) {
        boardController.clearCell(pos);
        onRemoveBlock(id);
      }
    }

    _isBlasting = false;
    notifyListeners();
    
    final result = BlastResult(
      success: true,
      destroyedBlockIds: targetBlockIds.toList(),
      destroyedPositions: targetPositions.toList(),
      destroyedCount: targetBlockIds.length,
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
