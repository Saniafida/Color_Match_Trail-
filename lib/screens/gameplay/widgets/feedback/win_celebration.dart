import 'package:flutter/material.dart';
import 'dart:math' as math;

class WinCelebration extends StatefulWidget {
  final VoidCallback onComplete;

  const WinCelebration({
    super.key,
    required this.onComplete,
  });

  @override
  State<WinCelebration> createState() => _WinCelebrationState();
}

class _WinCelebrationState extends State<WinCelebration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int particleCount = 50;
  final List<_Particle> particles = [];
  final math.Random random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    for (int i = 0; i < particleCount; i++) {
      particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.5 + 0.5, // Start in lower half
        vx: (random.nextDouble() - 0.5) * 2,
        vy: -random.nextDouble() * 3 - 1,
        color: _getRandomColor(),
        size: random.nextDouble() * 10 + 5,
      ));
    }

    _controller.addListener(() {
      setState(() {
        for (var p in particles) {
          p.x += p.vx * 0.01;
          p.y += p.vy * 0.01;
          p.vy += 0.05; // Gravity
        }
      });
    });

    _controller.forward().then((_) => widget.onComplete());
  }

  Color _getRandomColor() {
    const colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple, Colors.orange];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(particles: particles),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, size;
  Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.size});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      paint.color = p.color;
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
