import '../../models/models.dart';

class SpecialConfig {
  static const int lineThreshold = 5;
  static const int bombThreshold = 6;
  static const int colorThreshold = 7;

  // Area of bomb
  static const int bombRadius = 1; // 3x3 (center + 1)
  
  // Area of bomb + bomb
  static const int megaBombRadius = 2; // 5x5 (center + 2)
  
  // Animation duration
  static const Duration creationDuration = Duration(milliseconds: 300);
  static const Duration activationDuration = Duration(milliseconds: 400);

  static SpecialBlockType getCreationType(int length) {
    if (length >= colorThreshold) return SpecialBlockType.colorSpecial;
    if (length >= bombThreshold) return SpecialBlockType.bomb;
    if (length >= lineThreshold) {
      // By default, alternate or randomly pick horizontal/vertical?
      // For determinism in this implementation, we can just use horizontalLine
      // Or base it on the geometry of the trail (future enhancement).
      return SpecialBlockType.horizontalLine; 
    }
    return SpecialBlockType.none;
  }
}
