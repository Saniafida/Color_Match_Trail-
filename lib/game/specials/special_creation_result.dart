import '../../models/models.dart';

class SpecialCreationResult {
  final bool created;
  final SpecialBlockType type;
  final String blockId;
  final Position position;
  final BlockColor color;
  final int sourceMatchLength;
  
  const SpecialCreationResult({
    required this.created,
    this.type = SpecialBlockType.none,
    this.blockId = '',
    this.position = const Position(0, 0),
    this.color = BlockColor.red,
    this.sourceMatchLength = 0,
  });
}
