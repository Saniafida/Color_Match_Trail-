import 'block.dart';
import 'position.dart';

enum PowerUpType {
  none,
  smallArea,   // 4 blocks connected (Power-Up A: small area blast)
  bomb,        // 5 blocks connected (Bomb: 3x3 explosion)
  crossBlast,  // 6 blocks connected (Power-Up B: Row + Column cross blast)
  colorBomb,   // 7 blocks connected (Power-Up C: Color bomb clears matching color)
  megaBomb,    // 8+ blocks connected (Power-Up D: 5x5 Mega Bomb / Strongest)
}

enum PowerUpState {
  idle,
  transforming,
  active,
  activating,
  consumed,
}

class PowerUpBlock {
  final String powerUpId;
  final Position position;
  final BlockColor sourceColor;
  final PowerUpType visualType;
  final PowerUpState state;
  final bool isColorSpecific;

  const PowerUpBlock({
    required this.powerUpId,
    required this.position,
    required this.sourceColor,
    required this.visualType,
    this.state = PowerUpState.idle,
    this.isColorSpecific = true,
  });

  PowerUpBlock copyWith({
    String? powerUpId,
    Position? position,
    BlockColor? sourceColor,
    PowerUpType? visualType,
    PowerUpState? state,
    bool? isColorSpecific,
  }) {
    return PowerUpBlock(
      powerUpId: powerUpId ?? this.powerUpId,
      position: position ?? this.position,
      sourceColor: sourceColor ?? this.sourceColor,
      visualType: visualType ?? this.visualType,
      state: state ?? this.state,
      isColorSpecific: isColorSpecific ?? this.isColorSpecific,
    );
  }
}
