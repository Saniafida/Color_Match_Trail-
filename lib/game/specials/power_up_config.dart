import '../../models/power_up_block.dart';
import '../../models/block.dart';

class PowerUpMappingRule {
  final int minConnectedBlocks;
  final int maxConnectedBlocks;
  final PowerUpType resultPowerUp;
  final SpecialBlockType specialType;
  final BlockType blockType;
  final String description;

  const PowerUpMappingRule({
    required this.minConnectedBlocks,
    required this.maxConnectedBlocks,
    required this.resultPowerUp,
    required this.specialType,
    required this.blockType,
    required this.description,
  });
}

class PowerUpConfig {
  /// Configurable mapping table for power-up creation based on trail length
  static const List<PowerUpMappingRule> defaultRules = [
    PowerUpMappingRule(
      minConnectedBlocks: 4,
      maxConnectedBlocks: 4,
      resultPowerUp: PowerUpType.smallArea,
      specialType: SpecialBlockType.smallArea,
      blockType: BlockType.rocket,
      description: 'Small Area Blast (4 blocks)',
    ),
    PowerUpMappingRule(
      minConnectedBlocks: 5,
      maxConnectedBlocks: 5,
      resultPowerUp: PowerUpType.bomb,
      specialType: SpecialBlockType.bomb,
      blockType: BlockType.bomb,
      description: 'Bomb 3x3 Explosion (5 blocks)',
    ),
    PowerUpMappingRule(
      minConnectedBlocks: 6,
      maxConnectedBlocks: 6,
      resultPowerUp: PowerUpType.crossBlast,
      specialType: SpecialBlockType.crossBlast,
      blockType: BlockType.rocket,
      description: 'Row & Column Cross Blast (6 blocks)',
    ),
    PowerUpMappingRule(
      minConnectedBlocks: 7,
      maxConnectedBlocks: 7,
      resultPowerUp: PowerUpType.colorBomb,
      specialType: SpecialBlockType.colorSpecial,
      blockType: BlockType.colorBomb,
      description: 'Color Bomb (7 blocks)',
    ),
    PowerUpMappingRule(
      minConnectedBlocks: 8,
      maxConnectedBlocks: 999,
      resultPowerUp: PowerUpType.megaBomb,
      specialType: SpecialBlockType.megaBomb,
      blockType: BlockType.colorBomb,
      description: 'Mega Bomb 5x5 (8+ blocks)',
    ),
  ];

  static const Duration convergenceDuration = Duration(milliseconds: 250);
  static const Duration transformationDuration = Duration(milliseconds: 300);
  static const Duration settleDuration = Duration(milliseconds: 150);

  /// Determines which power-up to create for a given connected trail length
  static PowerUpMappingRule? getRuleForLength(int length, [List<PowerUpMappingRule>? customRules]) {
    final rules = customRules ?? defaultRules;
    for (final rule in rules) {
      if (length >= rule.minConnectedBlocks && length <= rule.maxConnectedBlocks) {
        return rule;
      }
    }
    return null;
  }

  static PowerUpType getPowerUpTypeForLength(int length) {
    return getRuleForLength(length)?.resultPowerUp ?? PowerUpType.none;
  }

  static SpecialBlockType getSpecialBlockTypeForLength(int length) {
    return getRuleForLength(length)?.specialType ?? SpecialBlockType.none;
  }

  static BlockType getBlockTypeForLength(int length) {
    return getRuleForLength(length)?.blockType ?? BlockType.normal;
  }
}
