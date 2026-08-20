import '../../models/models.dart';
import '../trail/match_result.dart'; // To get SpecialCreationType

enum BlastIntensity {
  normal,
  large,
  mega
}

class BlastResult {
  final bool success;
  final List<String> destroyedBlockIds;
  final List<Position> destroyedPositions;
  final int destroyedCount;
  final BlockColor? color;
  final BlastIntensity intensity;
  final Duration duration;
  final SpecialCreationType specialCreationHint;
  final bool isClosedLoop;
  final DestructionSource source;

  const BlastResult({
    required this.success,
    this.destroyedBlockIds = const [],
    this.destroyedPositions = const [],
    this.destroyedCount = 0,
    this.color,
    this.intensity = BlastIntensity.normal,
    this.duration = Duration.zero,
    this.specialCreationHint = SpecialCreationType.none,
    this.isClosedLoop = false,
    this.source = DestructionSource.playerMatch,
  });
}
