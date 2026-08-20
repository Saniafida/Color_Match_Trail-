import '../../models/models.dart';

class SpecialActivationResult {
  final String specialBlockId;
  final SpecialBlockType specialType;
  final Position sourcePosition;
  final List<String> targetBlockIds;
  final List<Position> targetPositions;
  final int affectedCount;
  final BlockColor? activationColor;
  final bool success;

  const SpecialActivationResult({
    required this.specialBlockId,
    required this.specialType,
    required this.sourcePosition,
    this.targetBlockIds = const [],
    this.targetPositions = const [],
    this.affectedCount = 0,
    this.activationColor,
    this.success = true,
  });
}
