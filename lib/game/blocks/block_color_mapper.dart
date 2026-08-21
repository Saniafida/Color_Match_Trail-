import 'package:flutter/material.dart';
import '../../models/models.dart';

class BlockStyle {
  final Color main;
  final Color highlight;
  final Color shadow;
  final Color glow;
  final Color iconMain;
  final Color iconHighlight;
  final Color iconShadow;
  final IconData normalIcon;

  const BlockStyle({
    required this.main,
    required this.highlight,
    required this.shadow,
    required this.glow,
    required this.iconMain,
    required this.iconHighlight,
    required this.iconShadow,
    required this.normalIcon,
  });
}

class BlockColorMapper {
  static const Map<BlockColor, BlockStyle> _styles = {
    // RED: Toy Red with Heart icon ❤️
    BlockColor.red: BlockStyle(
      main: Color(0xFFE52521),
      highlight: Color(0xFFFF5252),
      shadow: Color(0xFF8B0000),
      glow: Color(0x99E52521),
      iconMain: Color(0xFF7A0000),
      iconHighlight: Color(0xFFFF8A80),
      iconShadow: Color(0xFF420000),
      normalIcon: Icons.favorite_rounded,
    ),
    // GREEN: Toy Green with Leaf icon 🍃
    BlockColor.green: BlockStyle(
      main: Color(0xFF43B929),
      highlight: Color(0xFF76D248),
      shadow: Color(0xFF1B5E20),
      glow: Color(0x9943B929),
      iconMain: Color(0xFF144D17),
      iconHighlight: Color(0xFFA5D6A7),
      iconShadow: Color(0xFF09290B),
      normalIcon: Icons.eco_rounded,
    ),
    // BLUE: Ocean Blue with Water Droplet icon 💧
    BlockColor.blue: BlockStyle(
      main: Color(0xFF1E88E5),
      highlight: Color(0xFF42A5F5),
      shadow: Color(0xFF0D47A1),
      glow: Color(0x991E88E5),
      iconMain: Color(0xFF083A85),
      iconHighlight: Color(0xFF90CAF9),
      iconShadow: Color(0xFF041E48),
      normalIcon: Icons.water_drop_rounded,
    ),
    // YELLOW: Golden Yellow with Crescent Moon icon 🌙
    BlockColor.yellow: BlockStyle(
      main: Color(0xFFFFD600),
      highlight: Color(0xFFFFF176),
      shadow: Color(0xFFE65100),
      glow: Color(0x99FFD600),
      iconMain: Color(0xFFB25000),
      iconHighlight: Color(0xFFFFFDE7),
      iconShadow: Color(0xFF5E2700),
      normalIcon: Icons.nightlight_round,
    ),
    // PURPLE: Vibrant Purple with Cloud icon ☁️
    BlockColor.purple: BlockStyle(
      main: Color(0xFFAB23C6),
      highlight: Color(0xFFCE52E5),
      shadow: Color(0xFF5B0E6D),
      glow: Color(0x99AB23C6),
      iconMain: Color(0xFF450654),
      iconHighlight: Color(0xFFEA80FC),
      iconShadow: Color(0xFF24022C),
      normalIcon: Icons.cloud_rounded,
    ),
    // ORANGE: Sunset Orange with Flame icon 🔥
    BlockColor.orange: BlockStyle(
      main: Color(0xFFFF7A00),
      highlight: Color(0xFFFF9E40),
      shadow: Color(0xFFB73A00),
      glow: Color(0x99FF7A00),
      iconMain: Color(0xFF8A2B00),
      iconHighlight: Color(0xFFFFCC80),
      iconShadow: Color(0xFF4D1700),
      normalIcon: Icons.local_fire_department_rounded,
    ),
  };

  static BlockStyle getStyle(BlockColor color) {
    return _styles[color] ?? _styles[BlockColor.red]!;
  }
}
