import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/service_locator.dart';
import '../blocks/block_color_mapper.dart';
import 'blast_result.dart';

class Particle {
  Offset position;
  Offset velocity;
  double size;
  double life;
  final double maxLife;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.life,
  }) : maxLife = life;
}

class BlastEffectWidget extends StatefulWidget {
  final BlockColor color;
  final BlastIntensity intensity;
  final VoidCallback onComplete;

  const BlastEffectWidget({
    super.key,
    required this.color,
    required this.intensity,
    required this.onComplete,
  });

  @override
  State<BlastEffectWidget> createState() => _BlastEffectWidgetState();
}

class _BlastEffectWidgetState extends State<BlastEffectWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  late BlockStyle _style;

  @override
  void initState() {
    super.initState();
    _style = BlockColorMapper.getStyle(widget.color);

    // Respect PerformanceManager particle budget
    final perfConfig = ServiceLocator.instance.performanceManager.config;
    int particleCount;
    Duration duration;

    switch (widget.intensity) {
      case BlastIntensity.mega:
        particleCount = perfConfig.particles.maxMegaBlastParticles;
        duration = const Duration(milliseconds: 600);
        break;
      case BlastIntensity.large:
        particleCount = perfConfig.particles.maxLargeBlastParticles;
        duration = const Duration(milliseconds: 500);
        break;
      default:
        particleCount = perfConfig.particles.maxSmallBlastParticles;
        duration = const Duration(milliseconds: 400);
        break;
    }

    for (int i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 40 + 20;
      _particles.add(Particle(
        position: Offset.zero,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        size: _random.nextDouble() * 6 + 4,
        life: duration.inMilliseconds / 1000.0,
      ));
    }

    _controller = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder + RepaintBoundary so only the canvas repaints,
    // not any parent widget tree. No setState needed here.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Update particle positions based on animation progress
          final dt = 0.05;
          for (final p in _particles) {
            if (p.life > 0) {
              p.position += p.velocity * dt;
              p.life -= dt;
            }
          }
          return CustomPaint(
            painter: _BlastPainter(_particles, _style, _controller.value),
          );
        },
      ),
    );
  }
}

class _BlastPainter extends CustomPainter {
  final List<Particle> particles;
  final BlockStyle style;
  final double progress;

  _BlastPainter(this.particles, this.style, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Radial glow
    final glowOpacity = (1.0 - progress).clamp(0.0, 1.0);
    if (glowOpacity > 0) {
      final glowPaint = Paint()
        ..color = style.glow.withValues(alpha: glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, 20 + (progress * 20), glowPaint);
    }

    // Particles
    for (final p in particles) {
      if (p.life <= 0) continue;
      final particleOpacity = (p.life / p.maxLife).clamp(0.0, 1.0);
      final particlePaint = Paint()
        ..color = style.highlight.withValues(alpha: particleOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center + p.position, p.size * particleOpacity, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlastPainter oldDelegate) => true;
}
