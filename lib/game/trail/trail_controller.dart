import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../board/board.dart';

typedef BlockLookup = Block? Function(String blockId);
typedef BlockUpdater = void Function(Block block);

class TrailController extends ChangeNotifier {
  final BoardController boardController;
  final BlockLookup getBlock;
  final BlockUpdater onUpdateBlock;
  final void Function(Trail) onTrailCompleted;

  Trail _activeTrail = const Trail(positions: [], blockIds: []);
  Trail get activeTrail => _activeTrail;

  bool _isDragging = false;
  bool get isDragging => _isDragging;

  TrailController({
    required this.boardController,
    required this.getBlock,
    required this.onUpdateBlock,
    required this.onTrailCompleted,
  });

  void handleDragStart(Position position) {
    if (!boardController.isValidPosition(position)) return;
    
    final blockId = boardController.getBlockId(position);
    if (blockId == null) return;
    
    final block = getBlock(blockId);
    if (block == null || block.isLocked || block.isBeingDestroyed) return;
    
    _isDragging = true;
    _activeTrail = Trail(
      color: block.color,
      positions: [position],
      blockIds: [blockId],
      isActive: true,
    );
    
    onUpdateBlock(block.copyWith(isSelected: true));
    notifyListeners();
  }

  void handleDragUpdate(Position position) {
    if (!_isDragging || !_activeTrail.isActive) return;
    
    // Ignore out of bounds
    if (!boardController.isValidPosition(position)) return;

    final blockId = boardController.getBlockId(position);
    if (blockId == null) return;

    final block = getBlock(blockId);
    if (block == null || block.isLocked || block.isBeingDestroyed) return;

    // Check for backtracking
    final index = _activeTrail.positions.indexOf(position);
    if (index != -1) {
      if (index < _activeTrail.positions.length - 1) {
        // Backtracked over a previous block. Deselect all blocks after it.
        final removedBlocks = _activeTrail.blockIds.sublist(index + 1);
        for (final id in removedBlocks) {
          final b = getBlock(id);
          if (b != null) onUpdateBlock(b.copyWith(isSelected: false));
        }
        
        _activeTrail = _activeTrail.copyWith(
          positions: _activeTrail.positions.sublist(0, index + 1),
          blockIds: _activeTrail.blockIds.sublist(0, index + 1),
        );
        notifyListeners();
      }
      return;
    }

    // Must be same color
    if (block.color != _activeTrail.color) return;

    // Must be orthogonally adjacent to the last block
    final lastPos = _activeTrail.positions.last;
    if (!_isOrthogonal(lastPos, position)) return;

    // Valid addition
    _activeTrail = _activeTrail.copyWith(
      positions: List.from(_activeTrail.positions)..add(position),
      blockIds: List.from(_activeTrail.blockIds)..add(blockId),
    );
    
    onUpdateBlock(block.copyWith(isSelected: true));
    notifyListeners();
  }

  void handleDragEnd() {
    if (!_isDragging) return;
    _isDragging = false;
    
    final finalTrail = _activeTrail.copyWith(isActive: false);
    onTrailCompleted(finalTrail);
    
    _clearActiveState();
  }

  void handleDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _clearActiveState();
  }

  void resetTrail() {
    _isDragging = false;
    _clearActiveState();
  }
  
  void _clearActiveState() {
    // Deselect all currently selected blocks from this trail
    for (final id in _activeTrail.blockIds) {
      final b = getBlock(id);
      if (b != null) onUpdateBlock(b.copyWith(isSelected: false));
    }
    
    _activeTrail = const Trail(positions: [], blockIds: []);
    notifyListeners();
  }

  bool _isOrthogonal(Position a, Position b) {
    final dr = (a.row - b.row).abs();
    final dc = (a.column - b.column).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }
}
