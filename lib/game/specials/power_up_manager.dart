import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../../models/power_up_block.dart';
import '../../models/destruction_source.dart';
import '../board/board.dart';
import '../blast/blast_controller.dart';
import '../blast/blast_result.dart';
import '../trail/match_result.dart';
import 'special_controller.dart';
import 'power_up_config.dart';

class PowerUpTransformationResult {
  final bool transformed;
  final String? transformedBlockId;
  final Position? targetPosition;
  final PowerUpType powerUpType;
  final SpecialBlockType specialType;
  final BlockColor sourceColor;
  final List<String> removedBlockIds;
  final List<Position> removedPositions;

  const PowerUpTransformationResult({
    required this.transformed,
    this.transformedBlockId,
    this.targetPosition,
    this.powerUpType = PowerUpType.none,
    this.specialType = SpecialBlockType.none,
    this.sourceColor = BlockColor.red,
    this.removedBlockIds = const [],
    this.removedPositions = const [],
  });
}

class PowerUpManager extends ChangeNotifier {
  final BoardController boardController;
  final Block? Function(String blockId) getBlock;
  final void Function(Block block) onUpdateBlock;
  final void Function(String blockId) onRemoveBlock;
  final SpecialController specialController;
  final BlastController blastController;

  PowerUpManager({
    required this.boardController,
    required this.getBlock,
    required this.onUpdateBlock,
    required this.onRemoveBlock,
    required this.specialController,
    required this.blastController,
  });

  /// Selects the transformation cell according to the strict priority rules:
  /// 1. Last selected block in the trail
  /// 2. Release position mapped to its connected cell
  /// 3. Center / nearest valid connected cell
  Position selectCreationCell({
    required List<Position> connectedPositions,
    Position? releasePosition,
  }) {
    if (connectedPositions.isEmpty) {
      throw ArgumentError('Connected positions cannot be empty.');
    }

    // Priority 1: Last selected block in the trail
    final lastPos = connectedPositions.last;
    if (boardController.isValidPosition(lastPos)) {
      return lastPos;
    }

    // Priority 2: Release position, mapped to its connected cell if in group
    if (releasePosition != null && connectedPositions.contains(releasePosition)) {
      return releasePosition;
    }

    // Priority 3: Center of connected group
    final middleIndex = connectedPositions.length ~/ 2;
    return connectedPositions[middleIndex];
  }

  /// Evaluates connected trail and performs the power-up transformation on the chosen block,
  /// while removing all other connected blocks.
  Future<PowerUpTransformationResult> processTrailPowerUp({
    required List<String> blockIds,
    required List<Position> positions,
    required BlockColor color,
    Position? releasePosition,
  }) async {
    final count = blockIds.length;
    final rule = PowerUpConfig.getRuleForLength(count);

    if (rule == null || rule.resultPowerUp == PowerUpType.none) {
      // 1-3 blocks: normal blast, no power-up
      return PowerUpTransformationResult(
        transformed: false,
        sourceColor: color,
        removedBlockIds: blockIds,
        removedPositions: positions,
      );
    }

    // Pick creation cell using priority order
    final targetPos = selectCreationCell(
      connectedPositions: positions,
      releasePosition: releasePosition,
    );

    // Find the block ID at the target position
    final targetIndex = positions.indexOf(targetPos);
    final chosenBlockId = (targetIndex >= 0 && targetIndex < blockIds.length)
        ? blockIds[targetIndex]
        : blockIds.last;

    final removedIds = <String>[];
    final removedPositions = <Position>[];

    for (int i = 0; i < blockIds.length; i++) {
      if (blockIds[i] != chosenBlockId) {
        removedIds.add(blockIds[i]);
        removedPositions.add(positions[i]);
      }
    }

    // Phase 1: Mark other blocks as being destroyed (energy pull toward chosen cell)
    for (final id in removedIds) {
      final b = getBlock(id);
      if (b != null) {
        onUpdateBlock(b.copyWith(
          isBeingDestroyed: true,
          isSelected: false,
        ));
      }
    }

    // Mark the chosen block as transforming
    final chosenBlock = getBlock(chosenBlockId);
    if (chosenBlock != null) {
      onUpdateBlock(chosenBlock.copyWith(
        isTransforming: true,
        isSelected: false,
      ));
    }

    // Phase 2: Convergence & Transformation Delay
    await Future.delayed(PowerUpConfig.convergenceDuration);

    // Physically remove other connected blocks from board
    for (int i = 0; i < removedPositions.length; i++) {
      final pos = removedPositions[i];
      final id = removedIds[i];
      boardController.clearCell(pos);
      onRemoveBlock(id);
    }

    // Phase 3: Transform chosen block into the power-up (inheriting source color)
    if (chosenBlock != null) {
      final powerUpBlock = chosenBlock.copyWith(
        specialType: rule.specialType,
        type: rule.blockType,
        color: color,
        isTransforming: false,
        isBeingDestroyed: false,
        isSelected: false,
      );
      onUpdateBlock(powerUpBlock);
    }

    await Future.delayed(PowerUpConfig.settleDuration);
    notifyListeners();

    return PowerUpTransformationResult(
      transformed: true,
      transformedBlockId: chosenBlockId,
      targetPosition: targetPos,
      powerUpType: rule.resultPowerUp,
      specialType: rule.specialType,
      sourceColor: color,
      removedBlockIds: removedIds,
      removedPositions: removedPositions,
    );
  }

  /// Activates a power-up on the board when tapped or triggered
  Future<BlastResult> activatePowerUpAt(Position position) async {
    final blockId = boardController.getBlockId(position);
    if (blockId == null) {
      return const BlastResult(success: false);
    }

    final block = getBlock(blockId);
    if (block == null || block.specialType == SpecialBlockType.none) {
      return const BlastResult(success: false);
    }

    // Trigger activation via SpecialController & BlastController
    final activationRequest = SpecialActivationRequest(
      blockId: block.id,
      position: block.position,
      type: block.specialType,
      color: block.color,
    );

    final specialResult = specialController.activateSpecial(activationRequest);
    
    // Execute blast on all affected targets
    final blastResult = await blastController.processMatch(
      MatchResult(
        isValid: true,
        length: specialResult.affectedCount,
        positions: specialResult.targetPositions,
        blockIds: specialResult.targetBlockIds,
        color: specialResult.activationColor,
        connectionType: ConnectionType.mega,
      ),
      source: DestructionSource.special,
    );

    notifyListeners();
    return blastResult;
  }
}
