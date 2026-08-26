import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../board/board.dart';
import 'special_config.dart';
import 'special_activation_result.dart';

class SpecialActivationRequest {
  final String blockId;
  final Position position;
  final SpecialBlockType type;
  final BlockColor color;

  const SpecialActivationRequest({
    required this.blockId,
    required this.position,
    required this.type,
    required this.color,
  });
}

class SpecialController extends ChangeNotifier {
  final BoardController boardController;
  final Block? Function(String blockId) getBlock;
  
  SpecialController({
    required this.boardController,
    required this.getBlock,
  });

  /// Evaluates special block activations, including chain reactions, returning the full set of targets.
  SpecialActivationResult activateSpecial(SpecialActivationRequest initialRequest) {
    final Queue<SpecialActivationRequest> queue = Queue();
    final Set<String> processedSpecialIds = {};
    
    // Overall targets collected across the entire chain reaction
    final Set<String> allTargetIds = {};
    final Set<Position> allTargetPositions = {};
    
    queue.add(initialRequest);
    
    while (queue.isNotEmpty) {
      final request = queue.removeFirst();
      if (processedSpecialIds.contains(request.blockId)) continue;
      
      processedSpecialIds.add(request.blockId);
      
      // Ensure the special block itself is targeted to be consumed
      allTargetIds.add(request.blockId);
      allTargetPositions.add(request.position);

      final newTargets = _calculateTargetsForType(request);
      
      // For each newly found target, add to our overall collection
      for (final pos in newTargets) {
        final targetId = boardController.getBlockId(pos);
        if (targetId == null) continue;
        
        allTargetIds.add(targetId);
        allTargetPositions.add(pos);
        
        // If this target is ALSO a special block that hasn't been activated yet, queue it!
        if (!processedSpecialIds.contains(targetId)) {
          final targetBlock = getBlock(targetId);
          if (targetBlock != null && targetBlock.specialType != SpecialBlockType.none) {
            queue.add(SpecialActivationRequest(
              blockId: targetId,
              position: pos,
              type: targetBlock.specialType,
              color: targetBlock.color,
            ));
          }
        }
      }
    }
    
    return SpecialActivationResult(
      success: true,
      specialBlockId: initialRequest.blockId,
      specialType: initialRequest.type,
      sourcePosition: initialRequest.position,
      targetBlockIds: allTargetIds.toList(),
      targetPositions: allTargetPositions.toList(),
      affectedCount: allTargetIds.length,
      activationColor: initialRequest.color,
    );
  }

  List<Position> _calculateTargetsForType(SpecialActivationRequest request) {
    final targets = <Position>[];
    final rows = boardController.rows;
    final cols = boardController.columns;
    final center = request.position;

    switch (request.type) {
      case SpecialBlockType.horizontalLine:
        for (int c = 0; c < cols; c++) {
          targets.add(Position(center.row, c));
        }
        break;

      case SpecialBlockType.verticalLine:
        for (int r = 0; r < rows; r++) {
          targets.add(Position(r, center.column));
        }
        break;

      case SpecialBlockType.crossBlast:
        // Clears entire row + entire column
        for (int c = 0; c < cols; c++) {
          targets.add(Position(center.row, c));
        }
        for (int r = 0; r < rows; r++) {
          if (r != center.row) {
            targets.add(Position(r, center.column));
          }
        }
        break;

      case SpecialBlockType.smallArea:
        // Small area (diamond/cross of radius 1 around center)
        final List<List<int>> offsets = [
          [-1, 0], [1, 0], [0, -1], [0, 1]
        ];
        for (final offset in offsets) {
          final r = center.row + offset[0];
          final c = center.column + offset[1];
          if (r >= 0 && r < rows && c >= 0 && c < cols) {
            targets.add(Position(r, c));
          }
        }
        break;

      case SpecialBlockType.bomb:
        // Standard 3x3 explosive radius
        final radius = SpecialConfig.bombRadius;
        for (int r = center.row - radius; r <= center.row + radius; r++) {
          for (int c = center.column - radius; c <= center.column + radius; c++) {
            if (r >= 0 && r < rows && c >= 0 && c < cols) {
              targets.add(Position(r, c));
            }
          }
        }
        break;

      case SpecialBlockType.megaBomb:
        // Huge 5x5 explosive radius
        final radius = SpecialConfig.megaBombRadius;
        for (int r = center.row - radius; r <= center.row + radius; r++) {
          for (int c = center.column - radius; c <= center.column + radius; c++) {
            if (r >= 0 && r < rows && c >= 0 && c < cols) {
              targets.add(Position(r, c));
            }
          }
        }
        break;

      case SpecialBlockType.colorSpecial:
        // Find all blocks of this color
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final pos = Position(r, c);
            final id = boardController.getBlockId(pos);
            if (id != null) {
              final block = getBlock(id);
              if (block != null && block.color == request.color) {
                targets.add(pos);
              }
            }
          }
        }
        break;

      case SpecialBlockType.magicWand:
        // Magic Star Wand targets all cells across the board
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            targets.add(Position(r, c));
          }
        }
        break;

      case SpecialBlockType.none:
        break;
    }
    
    return targets;
  }
}
