import 'package:flutter/material.dart';
import '../../../../models/power_up_block.dart';

enum FxParticleShape { circle, spark, star, petal, confettiSquare }

class FxParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;
  double rotation;
  double rotationSpeed;
  Color color;
  FxParticleShape shape;
  double life; // 1.0 -> 0.0
  double decay;

  FxParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.alpha = 1.0,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
    this.shape = FxParticleShape.circle,
    this.life = 1.0,
    this.decay = 0.035,
  });

  bool update() {
    x += vx;
    y += vy;
    vx *= 0.94; // Air resistance
    vy *= 0.94;
    vy += 0.15; // Subtle gravity
    rotation += rotationSpeed;
    life -= decay;
    alpha = (life * 1.2).clamp(0.0, 1.0);
    return life > 0;
  }
}

class FxShockwave {
  final Offset center;
  final double maxRadius;
  final Color color;
  final Duration duration;
  double progress; // 0.0 -> 1.0

  FxShockwave({
    required this.center,
    required this.maxRadius,
    required this.color,
    this.duration = const Duration(milliseconds: 320),
    this.progress = 0.0,
  });
}

class FxRocketStreak {
  final Offset start;
  final Offset end;
  final Color color;
  final bool isHorizontal;
  double progress; // 0.0 -> 1.0

  FxRocketStreak({
    required this.start,
    required this.end,
    required this.color,
    required this.isHorizontal,
    this.progress = 0.0,
  });
}

class FxCreationPulse {
  final Offset center;
  final Color color;
  final PowerUpType powerUpType;
  double progress; // 0.0 -> 1.0

  FxCreationPulse({
    required this.center,
    required this.color,
    required this.powerUpType,
    this.progress = 0.0,
  });
}
