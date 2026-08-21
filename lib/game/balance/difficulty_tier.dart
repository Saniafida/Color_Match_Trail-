import 'package:flutter/material.dart';

enum DifficultyTier {
  easy,
  normal,
  hard,
  expert;

  static DifficultyTier fromString(String? value) {
    if (value == null) return DifficultyTier.normal;
    switch (value.toLowerCase().trim()) {
      case 'easy':
        return DifficultyTier.easy;
      case 'medium':
      case 'normal':
        return DifficultyTier.normal;
      case 'hard':
        return DifficultyTier.hard;
      case 'expert':
        return DifficultyTier.expert;
      default:
        return DifficultyTier.normal;
    }
  }

  String get displayName {
    switch (this) {
      case DifficultyTier.easy:
        return 'Easy';
      case DifficultyTier.normal:
        return 'Normal';
      case DifficultyTier.hard:
        return 'Hard';
      case DifficultyTier.expert:
        return 'Expert';
    }
  }

  Color get color {
    switch (this) {
      case DifficultyTier.easy:
        return const Color(0xFF4CAF50); // Green
      case DifficultyTier.normal:
        return const Color(0xFF2196F3); // Blue
      case DifficultyTier.hard:
        return const Color(0xFFFF9800); // Orange
      case DifficultyTier.expert:
        return const Color(0xFFE91E63); // Crimson/Pink
    }
  }

  int get recommendedColorCount {
    switch (this) {
      case DifficultyTier.easy:
        return 3;
      case DifficultyTier.normal:
        return 4;
      case DifficultyTier.hard:
        return 5;
      case DifficultyTier.expert:
        return 6;
    }
  }

  double get complexityWeight {
    switch (this) {
      case DifficultyTier.easy:
        return 1.0;
      case DifficultyTier.normal:
        return 1.5;
      case DifficultyTier.hard:
        return 2.2;
      case DifficultyTier.expert:
        return 3.0;
    }
  }
}
