import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../app/routes/routes.dart';

class HeartsFullDialog extends StatelessWidget {
  final VoidCallback? onPlayNow;

  const HeartsFullDialog({
    super.key,
    this.onPlayNow,
  });

  static Future<bool> show(BuildContext context, {VoidCallback? onPlayNow}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => HeartsFullDialog(onPlayNow: onPlayNow),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
              // 1. Main Wood Signboard Body Frame
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
                      color: Color(0x338CE03E),
                      offset: Offset(0, 0),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Container(
                  // Inner Parchment / Cream Card Box
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
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
                        const SizedBox(height: 6),

                        // 2. Full Vibrant Heart with "5/5" Green Badge
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFEBEE),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE53935).withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/icons/icon_heart.png',
                                height: 72,
                                width: 72,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Circular Green "5/5" Full Badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8CE03E), Color(0xFF439906), Color(0xFF2E7D32)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white, width: 2.0),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 2),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, color: Colors.white, size: 12),
                                    SizedBox(width: 2),
                                    Text(
                                      '5/5',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 3. Headings
                        const Text(
                          'Your Hearts Are Full!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF3E200C),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You have all 5 hearts ready!\nYou can enjoy any level or mini-game right now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7A4E24),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 4. "PLAY NOW" Action Button
                        GestureDetector(
                          key: const ValueKey('hearts_full_play_btn'),
                          onTap: () {
                            Navigator.pop(context, true);
                            if (onPlayNow != null) {
                              onPlayNow!();
                            } else {
                              Navigator.pushNamed(context, AppRoutes.worldMap);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8CE03E),
                                  Color(0xFF4CAF50),
                                  Color(0xFF2E7D32),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDCEDC8), width: 2.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF1B5E20),
                                  offset: Offset(0, 4),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 6),
                                Text(
                                  'PLAY NOW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFF1B5E20),
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 5. Subtitle message
                        const Text(
                          '♥ Ready for endless adventure! ♥',
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

              // 6. Top Header Ribbon / Banner ("HEARTS FULL!")
              Positioned(
                top: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFlowerGarland(isLeft: true),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8CE03E),
                            Color(0xFF439906),
                            Color(0xFF286403),
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                          SizedBox(width: 4),
                          Text(
                            'HEARTS FULL!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              shadows: [
                                Shadow(color: Color(0xFF1B5E20), offset: Offset(1, 2), blurRadius: 2),
                              ],
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                        ],
                      ),
                    ),
                    _buildFlowerGarland(isLeft: false),
                  ],
                ),
              ),

              // 7. Bottom Center Close Button (✖)
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  key: const ValueKey('hearts_full_close_btn'),
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8D5325), Color(0xFF5D3312), Color(0xFF3E1F08)],
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

  Widget _buildFlowerGarland({required bool isLeft}) {
    return Transform.scale(
      scaleX: isLeft ? 1 : -1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF81C784),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD54F),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
