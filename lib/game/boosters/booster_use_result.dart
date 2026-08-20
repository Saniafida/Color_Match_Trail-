import '../../models/models.dart';

class BoosterUseResult {
  final bool success;
  final BoosterType boosterType;
  final bool consumed;
  final List<String> affectedBlockIds;
  final List<Position> affectedPositions;
  final DestructionSource source;
  final String? error;

  const BoosterUseResult({
    required this.success,
    required this.boosterType,
    this.consumed = false,
    this.affectedBlockIds = const [],
    this.affectedPositions = const [],
    this.source = DestructionSource.booster,
    this.error,
  });
}
