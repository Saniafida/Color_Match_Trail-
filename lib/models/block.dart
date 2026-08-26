import 'position.dart';
import 'power_up_block.dart';

enum BlockColor { red, green, blue, yellow, purple, orange }

enum BlockType { normal, rocket, bomb, colorBomb, otherSpecial }

enum SpecialBlockType {
  none,
  horizontalLine,
  verticalLine,
  bomb,
  colorSpecial,
  smallArea,
  crossBlast,
  megaBomb,
  magicWand;

  PowerUpType toPowerUpType() {
    switch (this) {
      case SpecialBlockType.smallArea:
      case SpecialBlockType.horizontalLine:
      case SpecialBlockType.verticalLine:
        return PowerUpType.smallArea;
      case SpecialBlockType.bomb:
        return PowerUpType.bomb;
      case SpecialBlockType.crossBlast:
        return PowerUpType.crossBlast;
      case SpecialBlockType.colorSpecial:
        return PowerUpType.colorBomb;
      case SpecialBlockType.megaBomb:
        return PowerUpType.megaBomb;
      case SpecialBlockType.magicWand:
        return PowerUpType.magicWand;
      case SpecialBlockType.none:
        return PowerUpType.none;
    }
  }

  static SpecialBlockType fromPowerUpType(PowerUpType type) {
    switch (type) {
      case PowerUpType.smallArea:
        return SpecialBlockType.smallArea;
      case PowerUpType.bomb:
        return SpecialBlockType.bomb;
      case PowerUpType.crossBlast:
        return SpecialBlockType.crossBlast;
      case PowerUpType.colorBomb:
        return SpecialBlockType.colorSpecial;
      case PowerUpType.megaBomb:
        return SpecialBlockType.megaBomb;
      case PowerUpType.magicWand:
        return SpecialBlockType.magicWand;
      case PowerUpType.none:
        return SpecialBlockType.none;
    }
  }
}

class Block {
  final String id;
  final BlockColor color;
  final BlockType type;
  final SpecialBlockType specialType;
  final Position position;
  final bool isVisible;
  final bool isActive;
  final bool isLocked;
  final bool isSelected;
  final bool isInTrail;
  final bool isNew;
  final bool isMatched;
  final bool isBeingDestroyed;
  final bool isTransforming;

  const Block({
    required this.id,
    required this.color,
    this.type = BlockType.normal,
    this.specialType = SpecialBlockType.none,
    required this.position,
    this.isVisible = true,
    this.isActive = true,
    this.isLocked = false,
    this.isSelected = false,
    this.isInTrail = false,
    this.isNew = true,
    this.isMatched = false,
    this.isBeingDestroyed = false,
    this.isTransforming = false,
  });

  bool get isPowerUp => specialType != SpecialBlockType.none || type != BlockType.normal;

  Block copyWith({
    String? id,
    BlockColor? color,
    BlockType? type,
    SpecialBlockType? specialType,
    Position? position,
    bool? isVisible,
    bool? isActive,
    bool? isLocked,
    bool? isSelected,
    bool? isInTrail,
    bool? isNew,
    bool? isMatched,
    bool? isBeingDestroyed,
    bool? isTransforming,
  }) {
    return Block(
      id: id ?? this.id,
      color: color ?? this.color,
      type: type ?? this.type,
      specialType: specialType ?? this.specialType,
      position: position ?? this.position,
      isVisible: isVisible ?? this.isVisible,
      isActive: isActive ?? this.isActive,
      isLocked: isLocked ?? this.isLocked,
      isSelected: isSelected ?? this.isSelected,
      isInTrail: isInTrail ?? this.isInTrail,
      isNew: isNew ?? this.isNew,
      isMatched: isMatched ?? this.isMatched,
      isBeingDestroyed: isBeingDestroyed ?? this.isBeingDestroyed,
      isTransforming: isTransforming ?? this.isTransforming,
    );
  }
}
