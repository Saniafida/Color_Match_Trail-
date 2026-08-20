import '../../models/models.dart';
import '../board/board.dart';
import 'match_result.dart';

class ConnectionValidator {
  final BoardController boardController;
  final Block? Function(String) getBlock;
  final int minimumConnectionLength;

  ConnectionValidator({
    required this.boardController,
    required this.getBlock,
    this.minimumConnectionLength = 3,
  });

  MatchResult validate(Trail trail) {
    if (trail.positions.isEmpty || trail.blockIds.isEmpty) {
      return const MatchResult(
        isValid: false,
        invalidReason: InvalidConnectionReason.emptyTrail,
        connectionType: ConnectionType.invalid,
      );
    }

    final length = trail.positions.length;

    if (length != trail.blockIds.length) {
      return MatchResult(
        isValid: false,
        length: length,
        invalidReason: InvalidConnectionReason.invalidTrailState,
        connectionType: ConnectionType.invalid,
      );
    }

    final uniquePositions = trail.positions.toSet();
    if (uniquePositions.length != length) {
      return MatchResult(
        isValid: false,
        length: length,
        invalidReason: InvalidConnectionReason.duplicatePosition,
        connectionType: ConnectionType.invalid,
      );
    }

    final uniqueIds = trail.blockIds.toSet();
    if (uniqueIds.length != length) {
      return MatchResult(
        isValid: false,
        length: length,
        invalidReason: InvalidConnectionReason.duplicateBlock,
        connectionType: ConnectionType.invalid,
      );
    }

    final trailColor = trail.color;
    if (trailColor == null) {
      return MatchResult(
        isValid: false,
        length: length,
        invalidReason: InvalidConnectionReason.invalidColor,
        connectionType: ConnectionType.invalid,
      );
    }

    for (int i = 0; i < length; i++) {
      final pos = trail.positions[i];
      final id = trail.blockIds[i];

      if (!boardController.isValidPosition(pos)) {
        return MatchResult(
          isValid: false,
          length: length,
          invalidReason: InvalidConnectionReason.invalidPosition,
          connectionType: ConnectionType.invalid,
        );
      }

      final boardBlockId = boardController.getBlockId(pos);
      if (boardBlockId != id) {
        return MatchResult(
          isValid: false,
          length: length,
          invalidReason: InvalidConnectionReason.invalidBlock,
          connectionType: ConnectionType.invalid,
        );
      }

      final block = getBlock(id);
      if (block == null) {
        return MatchResult(
          isValid: false,
          length: length,
          invalidReason: InvalidConnectionReason.invalidBlock,
          connectionType: ConnectionType.invalid,
        );
      }

      if (block.isLocked) {
        return MatchResult(
          isValid: false,
          length: length,
          invalidReason: InvalidConnectionReason.lockedBlock,
          connectionType: ConnectionType.invalid,
        );
      }

      if (block.isBeingDestroyed) {
        return MatchResult(
          isValid: false,
          length: length,
          invalidReason: InvalidConnectionReason.inactiveBlock,
          connectionType: ConnectionType.invalid,
        );
      }

      if (block.color != trailColor) {
        return MatchResult(
          isValid: false,
          length: length,
          invalidReason: InvalidConnectionReason.differentColor,
          connectionType: ConnectionType.invalid,
        );
      }

      if (i > 0) {
        final prevPos = trail.positions[i - 1];
        if (!_isOrthogonal(prevPos, pos)) {
          return MatchResult(
            isValid: false,
            length: length,
            invalidReason: InvalidConnectionReason.nonAdjacent,
            connectionType: ConnectionType.invalid,
          );
        }
      }
    }

    if (length < minimumConnectionLength) {
      return MatchResult(
        isValid: false,
        color: trailColor,
        length: length,
        blockIds: trail.blockIds,
        positions: trail.positions,
        invalidReason: InvalidConnectionReason.insufficientLength,
        connectionType: ConnectionType.none,
      );
    }

    ConnectionType type;
    if (length >= 7) {
      type = ConnectionType.mega;
    } else if (length >= 5) {
      type = ConnectionType.large;
    } else {
      type = ConnectionType.normal;
    }

    SpecialCreationType specialHint = SpecialCreationType.none;
    if (length >= 7) {
      specialHint = SpecialCreationType.megaSpecial;
    } else if (length >= 5) {
      specialHint = SpecialCreationType.bomb;
    }

    return MatchResult(
      isValid: true,
      color: trailColor,
      length: length,
      blockIds: trail.blockIds,
      positions: trail.positions,
      connectionType: type,
      invalidReason: InvalidConnectionReason.none,
      specialCreationHint: specialHint,
      isClosedLoop: false, // Future proof hook
    );
  }

  bool _isOrthogonal(Position a, Position b) {
    final dr = (a.row - b.row).abs();
    final dc = (a.column - b.column).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }
}
