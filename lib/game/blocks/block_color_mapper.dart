import 'package:flutter/material.dart';
import '../../models/models.dart';

class BlockStyle {
  final Color main;
  final Color highlight;
  final Color shadow;
  final Color glow;

  const BlockStyle({
    required this.main,
    required this.highlight,
    required this.shadow,
    required this.glow,
  });
}

class BlockColorMapper {
  static const Map<BlockColor, BlockStyle> _styles = {
    BlockColor.red: BlockStyle(
      main: Color(0xFFE53935),
      highlight: Color(0xFFFF8A80),
      shadow: Color(0xFFB71C1C),
      glow: Color(0x66E53935),
    ),
    BlockColor.green: BlockStyle(
      main: Color(0xFF43A047),
      highlight: Color(0xFFB9F6CA),
      shadow: Color(0xFF1B5E20),
      glow: Color(0x6643A047),
    ),
    BlockColor.blue: BlockStyle(
      main: Color(0xFF1E88E5),
      highlight: Color(0xFF82B1FF),
      shadow: Color(0xFF0D47A1),
      glow: Color(0x661E88E5),
    ),
    BlockColor.yellow: BlockStyle(
      main: Color(0xFFFFB300),
      highlight: Color(0xFFFFE57F),
      shadow: Color(0xFFFF6F00),
      glow: Color(0x66FFB300),
    ),
    BlockColor.purple: BlockStyle(
      main: Color(0xFF8E24AA),
      highlight: Color(0xFFEA80FC),
      shadow: Color(0xFF4A148C),
      glow: Color(0x668E24AA),
    ),
  };

  static BlockStyle getStyle(BlockColor color) {
    return _styles[color] ?? _styles[BlockColor.red]!;
  }
}
