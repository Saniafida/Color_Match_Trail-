import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_panel_modal.dart';
import '../../widgets/common/game_bottom_nav_bar.dart';
import '../../widgets/buttons/glossy_button.dart';

class SpinPrize {
  final String label;
  final String type; // 'coins' or 'gems'
  final int amount;
  final Color color;

  const SpinPrize({
    required this.label,
    required this.type,
    required this.amount,
    required this.color,
  });
}

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _animation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  int _freeSpins = 1;

  final List<SpinPrize> _prizes = const [
    SpinPrize(label: '10', type: 'gems', amount: 10, color: Color(0xFF9C27B0)),
    SpinPrize(label: '200', type: 'coins', amount: 200, color: Color(0xFF1E88E5)),
    SpinPrize(label: '15', type: 'gems', amount: 15, color: Color(0xFFAB47BC)),
    SpinPrize(label: '100', type: 'coins', amount: 100, color: Color(0xFF43A047)),
    SpinPrize(label: '5', type: 'gems', amount: 5, color: Color(0xFFE53935)),
    SpinPrize(label: '250', type: 'coins', amount: 250, color: Color(0xFF039BE5)),
    SpinPrize(label: '20', type: 'gems', amount: 20, color: Color(0xFF7CB342)),
    SpinPrize(label: '150', type: 'coins', amount: 150, color: Color(0xFFFB8C00)),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      if (_freeSpins > 0) _freeSpins--;
    });

    final random = Random();
    final targetIndex = random.nextInt(_prizes.length);
    final sectorAngle = (2 * pi) / _prizes.length;

    // Calculate final angle (extra full rotations + exact sector offset)
    final extraRounds = 5 + random.nextInt(3);
    final targetSectorCenter = (targetIndex * sectorAngle) + (sectorAngle / 2);
    final finalAngle = _currentAngle + (extraRounds * 2 * pi) + (2 * pi - targetSectorCenter);

    _animation = Tween<double>(begin: _currentAngle, end: finalAngle).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _currentAngle = _animation.value;
        });
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onSpinComplete(targetIndex);
        }
      });

    _spinController.forward(from: 0);
  }

  void _onSpinComplete(int winningIndex) {
    setState(() {
      _isSpinning = false;
    });

    final prize = _prizes[winningIndex];
    if (prize.type == 'coins') {
      ServiceLocator.instance.coinManager.addCoins(prize.amount);
    }

    _showPrizeDialog(prize);
  }

  void _showPrizeDialog(SpinPrize prize) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A3B14), Color(0xFF331705)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD54F), width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black54, offset: Offset(0, 8), blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONGRATULATIONS! 🎉',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Image.asset(
                prize.type == 'coins'
                    ? 'assets/images/icons/icon_coin.png'
                    : 'assets/images/icons/icon_gem.png',
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 10),
              Text(
                'You Won +${prize.amount} ${prize.type.toUpperCase()}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GlossyButton(
                text: 'Awesome!',
                color: GlossyButtonColor.green,
                height: 46,
                fontSize: 16,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WoodPanelModal(
      title: 'Spin Wheel',
      subtitle: 'Spin and win exciting prizes!',
      activeTab: GameBottomTab.spin,
      onClose: () => Navigator.pop(context),
      bottomButton: GlossyButton(
        text: 'Spin',
        icon: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 22),
        color: _isSpinning ? GlossyButtonColor.blue : GlossyButtonColor.green,
        height: 52,
        fontSize: 18,
        onPressed: _isSpinning ? null : _spin,
      ),
      footerInfo: Text(
        'Daily Free Spin: $_freeSpins',
        style: const TextStyle(
          color: Color(0xFFFFE082),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // The Spinning Wheel
            Transform.rotate(
              angle: _currentAngle,
              child: CustomPaint(
                size: const Size(260, 260),
                painter: _WheelPainter(prizes: _prizes),
              ),
            ),

            // Golden Center Star Hub
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFEE58), Color(0xFFFFA000), Color(0xFFE65100)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: const Color(0xFFFFF9C4), width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 32),
            ),

            // Top Purple Pointer Needle (At 12 o'clock)
            Positioned(
              top: -16,
              child: _buildPointer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointer() {
    return Container(
      width: 32,
      height: 40,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 3),
        ],
      ),
      child: CustomPaint(
        painter: _PointerPainter(),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<SpinPrize> prizes;

  _WheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / prizes.length;

    // Draw Outer Wooden Rim
    final rimPaint = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(center, radius, rimPaint);

    final goldBorderPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius + 4, goldBorderPaint);
    canvas.drawCircle(center, radius - 7, goldBorderPaint);

    // Draw Segments
    for (int i = 0; i < prizes.length; i++) {
      final startAngle = (i * sweepAngle) - (pi / 2);
      final prize = prizes[i];

      final segmentPaint = Paint()
        ..color = prize.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 7),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );

      // Draw segment divider
      final dividerPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 7),
        startAngle,
        sweepAngle,
        true,
        dividerPaint,
      );

      // Draw Label and Icon indicator
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + (sweepAngle / 2) + (pi / 2));

      final textSpan = TextSpan(
        text: prize.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -radius + 36),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, size.height * 0.3);
    path.lineTo(size.width * 0.2, 0);
    path.lineTo(size.width * 0.8, 0);
    path.lineTo(size.width, size.height * 0.3);
    path.close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFBA68C8), Color(0xFF7B1FA2), Color(0xFF4A148C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // Gem in top of pointer
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.35),
      4.5,
      Paint()..color = const Color(0xFFFFD54F),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
