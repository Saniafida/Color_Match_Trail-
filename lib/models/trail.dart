import 'position.dart';
import 'block.dart';

class Trail {
  final List<Position> positions;
  final List<String> blockIds;
  final BlockColor? color;
  final bool isActive;

  const Trail({
    this.positions = const [],
    this.blockIds = const [],
    this.color,
    this.isActive = false,
  });

  Trail copyWith({
    List<Position>? positions,
    List<String>? blockIds,
    BlockColor? color,
    bool? isActive,
  }) {
    return Trail(
      positions: positions ?? this.positions,
      blockIds: blockIds ?? this.blockIds,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }
}
