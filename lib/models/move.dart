import 'block.dart';

class Move {
  final int moveNumber;
  final BlockColor? color;
  final List<String> connectedBlockIds;
  final int connectedBlockCount;
  final DateTime createdAt;
  final int blastSize;
  final int comboNumber;
  final BlockType? specialBlockCreated;
  final String? boosterUsed;

  const Move({
    required this.moveNumber,
    this.color,
    this.connectedBlockIds = const [],
    this.connectedBlockCount = 0,
    required this.createdAt,
    this.blastSize = 0,
    this.comboNumber = 0,
    this.specialBlockCreated,
    this.boosterUsed,
  });

  Move copyWith({
    int? moveNumber,
    BlockColor? color,
    List<String>? connectedBlockIds,
    int? connectedBlockCount,
    DateTime? createdAt,
    int? blastSize,
    int? comboNumber,
    BlockType? specialBlockCreated,
    String? boosterUsed,
  }) {
    return Move(
      moveNumber: moveNumber ?? this.moveNumber,
      color: color ?? this.color,
      connectedBlockIds: connectedBlockIds ?? this.connectedBlockIds,
      connectedBlockCount: connectedBlockCount ?? this.connectedBlockCount,
      createdAt: createdAt ?? this.createdAt,
      blastSize: blastSize ?? this.blastSize,
      comboNumber: comboNumber ?? this.comboNumber,
      specialBlockCreated: specialBlockCreated ?? this.specialBlockCreated,
      boosterUsed: boosterUsed ?? this.boosterUsed,
    );
  }
}
