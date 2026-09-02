import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';

class OutOfHeartsDialog extends StatelessWidget {
  const OutOfHeartsDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => const OutOfHeartsDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final livesManager = ServiceLocator.instance.livesManager;
    final coinManager = ServiceLocator.instance.coinManager;
    final gemManager = ServiceLocator.instance.gemManager;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 335,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 1. Main Wood Signboard Body Frame (Warm Mahogany & Walnut Wood)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 22, bottom: 18),
                padding: const EdgeInsets.fromLTRB(14, 28, 14, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6D3C18),
                      Color(0xFF4A250B),
                      Color(0xFF2E1505),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFF9E5D2A),
                    width: 4.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 8),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Color(0x33FFD54F),
                      offset: Offset(0, 0),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Container(
                  // Inner Parchment / Cream Card Box
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFFDF5),
                        Color(0xFFFBF1DB),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5D2A6),
                      width: 1.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 2. Broken Heart Graphic with "0" Count Badge
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset(
                                'assets/images/lose_screen/broken_heart.png',
                                height: 72,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Circular Red Zero Badge
                            Positioned(
                              bottom: 2,
                              right: 4,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF5252), Color(0xFFD32F2F), Color(0xFFB71C1C)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      offset: Offset(0, 2),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Headings
                        const Text(
                          'You are out of hearts!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF3E200C),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Get more hearts and keep playing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7A4E24),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 3. Option 1 Card (Spend 5 Gems)
                        _buildOptionCard(
                          leading: _buildHeartWithPlusFive(),
                          title: 'Continue',
                          subtitle: 'Play by spending\n5 Gems.',
                          actionButton: _buildGlossyButton(
                            key: const ValueKey('out_of_hearts_gems_btn'),
                            text: '5',
                            leadingWidget: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/icons/icon_gem.png',
                                width: 17,
                                height: 17,
                                fit: BoxFit.contain,
                              ),
                            ),
                            gradientColors: const [
                              Color(0xFF76D636),
                              Color(0xFF4CAF50),
                              Color(0xFF2E7D32),
                            ],
                            borderColor: const Color(0xFFDCEDC8),
                            shadowColor: const Color(0xFF1B5E20),
                            onTap: () async {
                              final success = await livesManager.refillWithGems(gemManager);
                              if (context.mounted) {
                                if (success) {
                                  Navigator.pop(context, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '❤️ 5 Hearts Refilled! Keep Playing!',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: Color(0xFF2E7D32),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Not enough gems! Need 5 Gems to refill hearts.',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: Color(0xFFC62828),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 4. "OR" Divider Pill (Wood & Gold)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8D5325), Color(0xFF5D3312)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 1.4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 2),
                            ],
                          ),
                          child: const Text(
                            'OR',
                            style: TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 5. Option 2 Card (Spend 100 Coins)
                        _buildOptionCard(
                          leading: Image.asset(
                            'assets/images/icons/icon_coin.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                          ),
                          title: 'Continue',
                          subtitle: 'Play by spending\n100 Coins.',
                          actionButton: _buildGlossyButton(
                            key: const ValueKey('out_of_hearts_coins_btn'),
                            text: '100',
                            leadingWidget: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF9C4),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/icons/icon_coin.png',
                                width: 17,
                                height: 17,
                                fit: BoxFit.contain,
                              ),
                            ),
                            gradientColors: const [
                              Color(0xFFFFD54F),
                              Color(0xFFFFB300),
                              Color(0xFFFF8F00),
                            ],
                            borderColor: const Color(0xFFFFF9C4),
                            shadowColor: const Color(0xFFBF360C),
                            onTap: () async {
                              final success = await livesManager.refillWithCoins(coinManager);
                              if (context.mounted) {
                                if (success) {
                                  Navigator.pop(context, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '❤️ 5 Hearts Refilled! Keep Playing!',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: Color(0xFF2E7D32),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Not enough coins! Need 100 Coins to refill hearts.',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: Color(0xFFC62828),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 6. Subtitle: "♥ Don't lose your progress! ♥"
                        const Text(
                          '♥ Don\'t lose your progress! ♥',
                          style: TextStyle(
                            color: Color(0xFF8D5325),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 7. Top Header Ribbon / Banner ("Out of Hearts!")
              Positioned(
                top: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFlowerGarland(isLeft: true),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE53935),
                            Color(0xFFC62828),
                            Color(0xFFB71C1C),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            offset: Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Out of Hearts!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(color: Color(0xFF4A0000), offset: Offset(1, 2), blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                    _buildFlowerGarland(isLeft: false),
                  ],
                ),
              ),

              // 8. Bottom Center Close Button (✖)
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  key: const ValueKey('out_of_hearts_close_btn'),
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8D5325), Color(0xFF5D3312), Color(0xFF3E200C)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFFF7EA),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required Widget actionButton,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF5D3A1A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          actionButton,
        ],
      ),
    );
  }

  Widget _buildHeartWithPlusFive() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/icons/icon_heart.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
        ),
        const Text(
          '+5',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlossyButton({
    Key? key,
    required String text,
    IconData? icon,
    Widget? leadingWidget,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 2),
              blurRadius: 0,
            ),
            const BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 3),
              blurRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 4),
              ],
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowerGarland({required bool isLeft}) {
    return Transform.scale(
      scaleX: isLeft ? 1 : -1,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌸', style: TextStyle(fontSize: 16)),
          SizedBox(width: 2),
          Text('🍃', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
