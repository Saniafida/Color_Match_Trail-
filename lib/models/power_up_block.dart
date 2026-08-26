import 'block.dart';
import 'position.dart';

enum PowerUpType {
  none,
  smallArea,   // 4 blocks connected (Rocket: small area blast)
  bomb,        // 5 blocks connected (Bomb: 3x3 explosion)
  crossBlast,  // 6 blocks connected (Cross Rocket: Row + Column cross blast)
  colorBomb,   // 7 blocks connected (Pinwheel: Color bomb clears matching color)
  megaBomb,    // 8 blocks connected (Disco Ball: 5x5 Mega Bomb)
  magicWand,   // 9+ blocks connected (Star Wand: Full Board Magic Blast)
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
