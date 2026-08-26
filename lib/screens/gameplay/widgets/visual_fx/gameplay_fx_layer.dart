import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'gameplay_fx_controller.dart';
import 'gameplay_fx_models.dart';

class GameplayFxLayer extends StatefulWidget {
  final GameplayFxController controller;

  const GameplayFxLayer({
    super.key,
    required this.controller,
  });

  @override
  State<GameplayFxLayer> createState() => _GameplayFxLayerState();
}

class _GameplayFxLayerState extends State<GameplayFxLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? 0.016
        : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    widget.controller.tick(dt.clamp(0.005, 0.05));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _GameplayFxPainter(
            particles: widget.controller.particles,
            shockwaves: widget.controller.shockwaves,
            rocketStreaks: widget.controller.rocketStreaks,
            creationPulses: widget.controller.creationPulses,
          ),
        );
      },
    );
  }
}

class _GameplayFxPainter extends CustomPainter {
  final List<FxParticle> particles;
  final List<FxShockwave> shockwaves;
  final List<FxRocketStreak> rocketStreaks;
  final List<FxCreationPulse> creationPulses;

  _GameplayFxPainter({
    required this.particles,
    required this.shockwaves,
    required this.rocketStreaks,
    required this.creationPulses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Shockwaves & Radial Glows
    for (final sw in shockwaves) {
      final currentRadius = sw.maxRadius * Curves.easeOutCubic.transform(sw.progress);
      final alpha = ((1.0 - sw.progress) * 0.85).clamp(0.0, 1.0);

      // Outer expanding ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1.0 - sw.progress) + 1.0
        ..color = sw.color.withValues(alpha: alpha);
      canvas.drawCircle(sw.center, currentRadius, ringPaint);

      // Inner radial flash
      final innerPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = sw.color.withValues(alpha: alpha * 0.45);
      canvas.drawCircle(sw.center, currentRadius * 0.75, innerPaint);
    }

    // 2. Power-Up Creation Pulse
    for (final cp in creationPulses) {
      final pulseProgress = Curves.easeInOutBack.transform(cp.progress);
      final radius = 28.0 + (1.0 - pulseProgress.clamp(0.0, 1.0)) * 18.0;
      final alpha = ((1.0 - cp.progress) * 0.9).clamp(0.0, 1.0);

      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = const Color(0xFFFFD700).withValues(alpha: alpha);
      canvas.drawCircle(cp.center, radius, pulsePaint);

      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = cp.color.withValues(alpha: alpha * 0.35);
      canvas.drawCircle(cp.center, radius * 0.8, glowPaint);
    }

    // 3. Directional Rocket Streaks
    for (final rs in rocketStreaks) {
      final currentPoint = Offset.lerp(rs.start, rs.end, rs.progress)!;
      final tailPoint = Offset.lerp(
        rs.start,
        rs.end,
        (rs.progress - 0.28).clamp(0.0, 1.0),
      )!;

      final streakPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6.0 * (1.0 - rs.progress * 0.3)
        ..color = rs.color.withValues(alpha: 0.9);

      canvas.drawLine(tailPoint, currentPoint, streakPaint);

      // Fiery head glow
      final headPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.95);
      canvas.drawCircle(currentPoint, 5.0, headPaint);
    }

    // 4. Particles (GPU fast batch rendering)
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.alpha);

      switch (p.shape) {
        case FxParticleShape.circle:
          canvas.drawCircle(Offset(p.x, p.y), p.size * 0.5, paint);
          break;

        case FxParticleShape.spark:
          canvas.save();
          canvas.translate(p.x, p.y);
          final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
          final angle = math.atan2(p.vy, p.vx);
          canvas.rotate(angle);
          final streakLength = math.max(p.size, speed * 2.2);
          final sparkRect = Rect.fromCenter(
            center: Offset.zero,
            width: streakLength,
            height: p.size * 0.45,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(sparkRect, const Radius.circular(2)),
            paint,
          );
          canvas.restore();
          break;

        case FxParticleShape.star:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rotation);
          _drawStar(canvas, p.size * 0.65, paint);
          canvas.restore();
          break;

        case FxParticleShape.petal:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rotation);
          final petalRect = Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 1.3,
            height: p.size * 0.6,
          );
          canvas.drawOval(petalRect, paint);
          canvas.restore();
          break;

        case FxParticleShape.confettiSquare:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rotation);
          final sqRect = Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.75,
          );
          canvas.drawRect(sqRect, paint);
          canvas.restore();
          break;
      }
    }
  }

  void _drawStar(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final r = (i.isEven) ? radius : innerRadius;
      final angle = (i * math.pi) / points - (math.pi / 2);
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GameplayFxPainter oldDelegate) => true;
}
