import 'position.dart';

enum BlockColor { red, green, blue, yellow, purple }

enum BlockType { normal, rocket, bomb, colorBomb, otherSpecial }

enum SpecialBlockType { none, horizontalLine, verticalLine, bomb, colorSpecial }

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
  });

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
    );
  }
}
