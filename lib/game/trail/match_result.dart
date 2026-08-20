import '../../models/models.dart';

enum ConnectionType {
  none,
  invalid,
  normal,
  large,
  mega,
}

enum InvalidConnectionReason {
  none,
  emptyTrail,
  insufficientLength,
  invalidColor,
  invalidBlock,
  duplicateBlock,
  duplicatePosition,
  invalidPosition,
  nonAdjacent,
  differentColor,
  inactiveBlock,
  lockedBlock,
  invalidTrailState,
}

enum SpecialCreationType {
  none,
  lineBlast,
  bomb,
  colorBomb,
  megaSpecial,
}

class MatchResult {
  final bool isValid;
  final BlockColor? color;
  final int length;
  final List<String> blockIds;
  final List<Position> positions;
  final ConnectionType connectionType;
  final InvalidConnectionReason invalidReason;
  final SpecialCreationType specialCreationHint;
  final bool isClosedLoop;

  const MatchResult({
    required this.isValid,
    this.color,
    this.length = 0,
    this.blockIds = const [],
    this.positions = const [],
    this.connectionType = ConnectionType.none,
    this.invalidReason = InvalidConnectionReason.none,
    this.specialCreationHint = SpecialCreationType.none,
    this.isClosedLoop = false,
  });
  
  MatchResult copyWith({
    bool? isValid,
    BlockColor? color,
    int? length,
    List<String>? blockIds,
    List<Position>? positions,
    ConnectionType? connectionType,
    InvalidConnectionReason? invalidReason,
    SpecialCreationType? specialCreationHint,
    bool? isClosedLoop,
  }) {
    return MatchResult(
      isValid: isValid ?? this.isValid,
      color: color ?? this.color,
      length: length ?? this.length,
      blockIds: blockIds ?? this.blockIds,
      positions: positions ?? this.positions,
      connectionType: connectionType ?? this.connectionType,
      invalidReason: invalidReason ?? this.invalidReason,
      specialCreationHint: specialCreationHint ?? this.specialCreationHint,
      isClosedLoop: isClosedLoop ?? this.isClosedLoop,
    );
  }
}
