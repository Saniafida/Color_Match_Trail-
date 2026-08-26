import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/block.dart';
import '../../../../models/power_up_block.dart';
import 'gameplay_fx_models.dart';

class GameplayFxController extends ChangeNotifier {
  final List<FxParticle> particles = [];
  final List<FxShockwave> shockwaves = [];
  final List<FxRocketStreak> rocketStreaks = [];
  final List<FxCreationPulse> creationPulses = [];

  final math.Random _random = math.Random();

  bool get hasActiveEffects =>
      particles.isNotEmpty ||
      shockwaves.isNotEmpty ||
      rocketStreaks.isNotEmpty ||
      creationPulses.isNotEmpty;

  void tick(double dt) {
    bool changed = false;

    if (particles.isNotEmpty) {
      particles.removeWhere((p) => !p.update());
      changed = true;
    }

    if (shockwaves.isNotEmpty) {
      for (final sw in shockwaves) {
        sw.progress += 0.055;
      }
      shockwaves.removeWhere((sw) => sw.progress >= 1.0);
      changed = true;
    }

    if (rocketStreaks.isNotEmpty) {
      for (final rs in rocketStreaks) {
        rs.progress += 0.085;
      }
      rocketStreaks.removeWhere((rs) => rs.progress >= 1.0);
      changed = true;
    }

    if (creationPulses.isNotEmpty) {
      for (final cp in creationPulses) {
        cp.progress += 0.045;
      }
      creationPulses.removeWhere((cp) => cp.progress >= 1.0);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// 1. Normal Block Clear Sparkle Pop
  void spawnMatchPop(Offset center, Color color, {int count = 10}) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 2.0 + _random.nextDouble() * 4.5;
      particles.add(
        FxParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 4.0 + _random.nextDouble() * 4.0,
          color: _tintColor(color, _random.nextDouble() * 0.3),
          shape: _random.nextBool() ? FxParticleShape.circle : FxParticleShape.spark,
          decay: 0.045 + _random.nextDouble() * 0.02,
        ),
      );
    }
    notifyListeners();
  }

  /// 2. Power-Up Creation Pulse & Celebration Sparks
  void spawnPowerUpCreation(Offset center, Color color, PowerUpType type) {
    creationPulses.add(
      FxCreationPulse(center: center, color: color, powerUpType: type),
    );

    shockwaves.add(
      FxShockwave(
        center: center,
        maxRadius: 45.0,
        color: const Color(0xFFFFD700),
      ),
    );

    // Burst of celebratory golden and matching sparkles
    for (int i = 0; i < 22; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 3.0 + _random.nextDouble() * 5.5;
      final isGold = _random.nextBool();
      particles.add(
        FxParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 5.0 + _random.nextDouble() * 4.5,
          color: isGold ? const Color(0xFFFFEB3B) : color,
          shape: FxParticleShape.star,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
          decay: 0.035,
        ),
      );
    }
    notifyListeners();
  }

  /// 3. Power-Up Activation / Blast Animation with theme-matched particles
  void spawnPowerUpBlast({
    required Offset center,
    required SpecialBlockType specialType,
    required Color sourceColor,
    bool isCombo = false,
  }) {
    final multiplier = isCombo ? 2.2 : 1.0;

    // Shockwave flash
    shockwaves.add(
      FxShockwave(
        center: center,
        maxRadius: (isCombo ? 110.0 : 75.0),
        color: _getShockwaveColor(specialType, sourceColor),
      ),
    );

    // Spawn theme-matched particles
    switch (specialType) {
      case SpecialBlockType.smallArea:
      case SpecialBlockType.horizontalLine:
      case SpecialBlockType.verticalLine:
        // Rocket / Line: Red & Gold fiery sparks & streaks
        _spawnRocketParticles(center, multiplier);
        break;

      case SpecialBlockType.bomb:
        // Bomb: Orange, red, and yellow explosive fiery chunks
        _spawnBombParticles(center, multiplier);
        break;

      case SpecialBlockType.crossBlast:
        // Cross Blast: Cyan laser sparks + bright energy bursts
        _spawnCrossBlastParticles(center, multiplier);
        break;

      case SpecialBlockType.colorSpecial:
        // Pinwheel: Radiating colorful swirling petals & streaks
        _spawnPinwheelParticles(center, multiplier);
        break;

      case SpecialBlockType.megaBomb:
        // Disco Mega: Rainbow confetti explosion
        _spawnDiscoConfettiParticles(center, multiplier);
        break;

      case SpecialBlockType.magicWand:
        // Magic Wand: Golden stars, fairy dust, and sparkling beams
        _spawnMagicWandParticles(center, multiplier);
        break;

      case SpecialBlockType.none:
        spawnMatchPop(center, sourceColor, count: (15 * multiplier).toInt());
        break;
    }

    notifyListeners();
  }

  /// Directional Rocket Streak
  void spawnRocketStreak({
    required Offset start,
    required Offset end,
    required Color color,
    required bool isHorizontal,
  }) {
    rocketStreaks.add(
      FxRocketStreak(
        start: start,
        end: end,
        color: color,
        isHorizontal: isHorizontal,
      ),
    );
    notifyListeners();
  }

  void _spawnRocketParticles(Offset center, double multiplier) {
    final count = (25 * multiplier).toInt();
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 3.5 + _random.nextDouble() * 6.5;
      final colors = [const Color(0xFFFF3D00), const Color(0xFFFF9100), Colors.white];
      particles.add(
        FxParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 4.5 + _random.nextDouble() * 4.0,
          color: colors[_random.nextInt(colors.length)],
          shape: FxParticleShape.spark,
          decay: 0.038,
        ),
      );
    }
  }

  void _spawnBombParticles(Offset center, double multiplier) {
    final count = (35 * multiplier).toInt();
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 4.0 + _random.nextDouble() * 8.0;
      final colors = [
        const Color(0xFFFF1744),
        const Color(0xFFFF6D00),
        const Color(0xFFFFD600),
        const Color(0xFF212121),
      ];
      particles.add(
        FxParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 5.0 + _random.nextDouble() * 6.0,
          color: colors[_random.nextInt(colors.length)],
          shape: _random.nextBool() ? FxParticleShape.circle : FxParticleShape.spark,
          decay: 0.032,
        ),
      );
    }
  }

  void _spawnCrossBlastParticles(Offset center, double multiplier) {
    final count = (30 * multiplier).toInt();
    for (int i = 0; i < count; i++) {
      final isAxis = _random.nextDouble() < 0.65;
      double angle;
      if (isAxis) {
        // Bias along 4 cardinal directions (cross laser beam)
        final cardinals = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
        angle = cardinals[_random.nextInt(4)] + (_random.nextDouble() - 0.5) * 0.3;
      } else {
        angle = _random.nextDouble() * 2 * math.pi;
      }
      final speed = 4.5 + _random.nextDouble() * 7.5;
      final colors = [const Color(0xFF00E5FF), const Color(0xFF18FFFF), Colors.white];
      particles.add(
        FxParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 4.5 + _random.nextDouble() * 5.0,
          color: colors[_random.nextInt(colors.length)],
          shape: FxParticleShape.spark,
          decay: 0.035,
        ),
      );
    }
  }

  void _spawnPinwheelParticles(Offset center, double multiplier) {
    final count = (35 * multiplier).toInt();
    final rainbow = [
      const Color(0xFFFF1744),
      const Color(0xFFFF9100),
      const Color(0xFFFFEA00),
      const Color(0xFF00E676),
      const Color(0xFF2979FF),
      const Color(0xFFAA00FF),
    ];
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (_random.nextDouble() * 0.4);
      final speed = 3.5 + _random.nextDouble() * 6.5;
      particles.add(
        FxParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 5.5 + _random.nextDouble() * 4.0,
          color: rainbow[i % rainbow.length],
          shape: FxParticleShape.petal,
          rotation: angle,
          rotationSpeed: 0.12,
          decay: 0.030,
        ),
      );
    }
  }

  void _spawnDiscoConfettiParticles(Offset center, double multiplier) {
    final count = (45 * multiplier).toInt();
    final rainbow = [
      const Color(0xFFFF1744),
      const Color(0xFFFF4081),
      const Color(0xFFFFEA00),
      const Color(0xFF00E676),
      const Color(0xFF00E5FF),
      const Color(0xFF651FFF),
      Colors.white,
    ];
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 4.0 + _random.nextDouble() * 8.5;
      particles.add(
        FxParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 1.5,
          size: 6.0 + _random.nextDouble() * 5.0,
          color: rainbow[_random.nextInt(rainbow.length)],
          shape: FxParticleShape.confettiSquare,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.4,
          decay: 0.025,
        ),
      );
    }
  }

  void _spawnMagicWandParticles(Offset center, double multiplier) {
    final count = (50 * multiplier).toInt();
    final starColors = [
      const Color(0xFFFFD700),
      const Color(0xFFFFEB3B),
      const Color(0xFFFFF9C4),
      const Color(0xFFE040FB),
      Colors.white,
    ];
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 3.0 + _random.nextDouble() * 9.0;
      particles.add(
        FxParticle(
          x: center.dx,
          y: center.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 6.0 + _random.nextDouble() * 6.0,
          color: starColors[_random.nextInt(starColors.length)],
          shape: FxParticleShape.star,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.35,
          decay: 0.028,
        ),
      );
    }
  }

  Color _getShockwaveColor(SpecialBlockType specialType, Color defaultColor) {
    switch (specialType) {
      case SpecialBlockType.smallArea:
      case SpecialBlockType.horizontalLine:
      case SpecialBlockType.verticalLine:
        return const Color(0xFFFF3D00);
      case SpecialBlockType.bomb:
        return const Color(0xFFFF9100);
      case SpecialBlockType.crossBlast:
        return const Color(0xFF00E5FF);
      case SpecialBlockType.colorSpecial:
        return const Color(0xFFFF4081);
      case SpecialBlockType.megaBomb:
        return const Color(0xFFFFD700);
      case SpecialBlockType.magicWand:
        return const Color(0xFFFFD700);
      case SpecialBlockType.none:
        return defaultColor;
    }
  }

  Color _tintColor(Color base, double amount) {
    return Color.lerp(base, Colors.white, amount) ?? base;
  }

  void clear() {
    particles.clear;
    shockwaves.clear;
    rocketStreaks.clear;
    creationPulses.clear;
    notifyListeners();
  }
}
