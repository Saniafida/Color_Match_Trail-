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
  final String assetPath;

  // Rich 3D toy-cube palette properties
  final Color baseLight;
  final Color baseDark;
  final Color bevelLight;
  final Color bevelDark;
  final Color bottomRim;
  final Color iconInner;

  const BlockStyle({
    required this.main,
    required this.highlight,
    required this.shadow,
    required this.glow,
    required this.iconMain,
    required this.iconHighlight,
    required this.iconShadow,
    required this.normalIcon,
    required this.assetPath,
    Color? baseLight,
    Color? baseDark,
    Color? bevelLight,
    Color? bevelDark,
    Color? bottomRim,
    Color? iconInner,
  })  : baseLight = baseLight ?? highlight,
        baseDark = baseDark ?? shadow,
        bevelLight = bevelLight ?? highlight,
        bevelDark = bevelDark ?? shadow,
        bottomRim = bottomRim ?? shadow,
        iconInner = iconInner ?? iconMain;
}

class BlockColorMapper {
  static const Map<BlockColor, BlockStyle> _styles = {
    // RED: Candy Toy Red with Heart ❤️ -> 1 (4).png
    BlockColor.red: BlockStyle(
      main: Color(0xFFE52521),
      highlight: Color(0xFFFF5252),
      shadow: Color(0xFF8B0000),
      glow: Color(0x99E52521),
      iconMain: Color(0xFF7A0000),
      iconHighlight: Color(0xFFFF8A80),
      iconShadow: Color(0xFF420000),
      normalIcon: Icons.favorite_rounded,
      assetPath: 'assets/blocks/1 (4).png',
      baseLight: Color(0xFFFF4842),
      baseDark: Color(0xFFD4151B),
      bevelLight: Color(0xFFFF9E9B),
      bevelDark: Color(0xFF9E0B12),
      bottomRim: Color(0xFF6E0006),
      iconInner: Color(0xFF850209),
    ),
    // GREEN: Vibrant Toy Green with Leaf 🍃 -> 1 (6).png
    BlockColor.green: BlockStyle(
      main: Color(0xFF43B929),
      highlight: Color(0xFF76D248),
      shadow: Color(0xFF1B5E20),
      glow: Color(0x9943B929),
      iconMain: Color(0xFF144D17),
      iconHighlight: Color(0xFFA5D6A7),
      iconShadow: Color(0xFF09290B),
      normalIcon: Icons.eco_rounded,
      assetPath: 'assets/blocks/1 (6).png',
      baseLight: Color(0xFF5CD82B),
      baseDark: Color(0xFF33A812),
      bevelLight: Color(0xFFAEF868),
      bevelDark: Color(0xFF1E7506),
      bottomRim: Color(0xFF104A02),
      iconInner: Color(0xFF196105),
    ),
    // BLUE: Ocean / Sky Blue with Water Drop 💧 -> 1 (5).png
    BlockColor.blue: BlockStyle(
      main: Color(0xFF1E88E5),
      highlight: Color(0xFF42A5F5),
      shadow: Color(0xFF0D47A1),
      glow: Color(0x991E88E5),
      iconMain: Color(0xFF083A85),
      iconHighlight: Color(0xFF90CAF9),
      iconShadow: Color(0xFF041E48),
      normalIcon: Icons.water_drop_rounded,
      assetPath: 'assets/blocks/1 (5).png',
      baseLight: Color(0xFF2EB7FF),
      baseDark: Color(0xFF0B7DDA),
      bevelLight: Color(0xFF99E3FF),
      bevelDark: Color(0xFF00529E),
      bottomRim: Color(0xFF00356B),
      iconInner: Color(0xFF004382),
    ),
    // YELLOW: Sunshine Golden Yellow with Crescent Moon 🌙 -> 1 (2).png
    BlockColor.yellow: BlockStyle(
      main: Color(0xFFFFD600),
      highlight: Color(0xFFFFF176),
      shadow: Color(0xFFE65100),
      glow: Color(0x99FFD600),
      iconMain: Color(0xFFB25000),
      iconHighlight: Color(0xFFFFFDE7),
      iconShadow: Color(0xFF5E2700),
      normalIcon: Icons.nightlight_round,
      assetPath: 'assets/blocks/1 (2).png',
      baseLight: Color(0xFFFFE53B),
      baseDark: Color(0xFFFFB800),
      bevelLight: Color(0xFFFFFFB2),
      bevelDark: Color(0xFFD47800),
      bottomRim: Color(0xFF964E00),
      iconInner: Color(0xFFA85700),
    ),
    // PURPLE: Royal Magenta / Purple with Cloud ☁️ -> 1 (1).png
    BlockColor.purple: BlockStyle(
      main: Color(0xFFAB23C6),
      highlight: Color(0xFFCE52E5),
      shadow: Color(0xFF5B0E6D),
      glow: Color(0x99AB23C6),
      iconMain: Color(0xFF450654),
      iconHighlight: Color(0xFFEA80FC),
      iconShadow: Color(0xFF24022C),
      normalIcon: Icons.cloud_rounded,
      assetPath: 'assets/blocks/1 (1).png',
      baseLight: Color(0xFFCC3CF0),
      baseDark: Color(0xFF9914B2),
      bevelLight: Color(0xFFF396FF),
      bevelDark: Color(0xFF6B0680),
      bottomRim: Color(0xFF430052),
      iconInner: Color(0xFF540366),
    ),
    // ORANGE: Sunset Tangerine with Flame 🔥 -> 1 (3).png
    BlockColor.orange: BlockStyle(
      main: Color(0xFFFF7A00),
      highlight: Color(0xFFFF9E40),
      shadow: Color(0xFFB73A00),
      glow: Color(0x99FF7A00),
      iconMain: Color(0xFF8A2B00),
      iconHighlight: Color(0xFFFFCC80),
      iconShadow: Color(0xFF4D1700),
      normalIcon: Icons.local_fire_department_rounded,
      assetPath: 'assets/blocks/1 (3).png',
      baseLight: Color(0xFFFF9626),
      baseDark: Color(0xFFEA6500),
      bevelLight: Color(0xFFFFCFA3),
      bevelDark: Color(0xFFB84200),
      bottomRim: Color(0xFF7A2500),
      iconInner: Color(0xFF8C2C00),
    ),
  };

  static BlockStyle getStyle(BlockColor color) {
    return _styles[color] ?? _styles[BlockColor.red]!;
  }

  static String getAssetPath(BlockColor color) {
    return getStyle(color).assetPath;
  }
}
