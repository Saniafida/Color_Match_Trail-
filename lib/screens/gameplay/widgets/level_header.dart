import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
import '../../../app/routes/routes.dart';
import '../../../widgets/dialogs/out_of_hearts_dialog.dart';

class LevelHeader extends StatelessWidget {
  final String levelId;
  final VoidCallback onPause;
  final VoidCallback? onSettings;
  final VoidCallback? onBack;

  const LevelHeader({
    super.key,
    required this.levelId,
    required this.onPause,
    this.onSettings,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final coinManager = ServiceLocator.instance.coinManager;
    final gemManager = ServiceLocator.instance.gemManager;
    final livesManager = ServiceLocator.instance.livesManager;

    final levelNumber = levelId.replaceAll(RegExp(r'[^0-9]'), '');

    return AnimatedBuilder(
      animation: Listenable.merge([coinManager, gemManager, livesManager]),
      builder: (context, _) {
        final coins = coinManager.balance;
        final gems = gemManager.balance;
        final livesLabel = livesManager.label;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7A431D),
                Color(0xFF53280B),
                Color(0xFF381705),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFFD54F),
              width: 2.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1E0C02),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0, 6),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Blue Glossy Circular 3D Back Button
              _buildBlueBackButton(context),

              const SizedBox(width: 4),

              // 2. Carved Wood Level Plaque with Foliage Leaves
              _buildLevelPlaque(levelNumber),

              const SizedBox(width: 4),

              // 3. Middle Area: Resource Counter Pills (Hearts, Coins, Gems)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hearts Pill
                      _buildResourcePill(
                        context: context,
                        iconAsset: 'assets/images/icons/icon_heart.png',
                        count: livesLabel,
                        hasPlus: true,
                        onTap: () => OutOfHeartsDialog.show(context),
                      ),
                      const SizedBox(width: 4),

                      // Coins Pill
                      _buildResourcePill(
                        context: context,
                        iconAsset: 'assets/images/icons/icon_coin.png',
                        count: '$coins',
                        hasPlus: true,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
                      ),
                      const SizedBox(width: 4),

                      // Gems Pill
                      _buildResourcePill(
                        context: context,
                        iconAsset: 'assets/images/icons/icon_gem.png',
                        count: '$gems',
                        hasPlus: true,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // 4. Pause Button [ || ]
              _buildPauseButton(),

              const SizedBox(width: 4),

              // 5. Golden Wood Settings Gear Button [ ⚙️ ]
              _buildSettingsButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlueBackButton(BuildContext context) {
    return GestureDetector(
      onTap: onBack ?? () => Navigator.maybePop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF42A5F5),
              Color(0xFF1E88E5),
              Color(0xFF0D47A1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFE3F2FD), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF072658),
              offset: Offset(0, 2.5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelPlaque(String levelNumber) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Little green leaves on top of the level sign
        Positioned(
          top: -7,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.4,
                child: const Icon(Icons.eco_rounded, color: Color(0xFF66BB6A), size: 14),
              ),
              Transform.rotate(
                angle: 0.4,
                child: const Icon(Icons.eco_rounded, color: Color(0xFF43A047), size: 14),
              ),
            ],
          ),
        ),

        // Wood Sign plaque
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5D3312),
                Color(0xFF3E1F08),
                Color(0xFF261203),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF160A02),
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black38,
                offset: Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Level',
                style: TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  height: 1.0,
                ),
              ),
              Text(
                levelNumber.isEmpty ? '1' : levelNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  shadows: [
                    Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResourcePill({
    required BuildContext context,
    required String iconAsset,
    required String count,
    bool hasPlus = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4A250B),
              Color(0xFF2E1505),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1E0C02),
              offset: Offset(0, 2),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Image.asset(
              iconAsset,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD54F),
                size: 18,
              ),
            ),
            const SizedBox(width: 4),

            // Number
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 1),
                ],
              ),
            ),

            // Plus button
            if (hasPlus) ...[
              const SizedBox(width: 3),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      offset: Offset(0, 1),
                      blurRadius: 1.5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: onPause,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF8D582A),
              Color(0xFF5D3312),
              Color(0xFF3E1F08),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF160A02),
              offset: Offset(0, 2),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 2.5),
              blurRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.pause_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: onSettings ??
          () {
            ServiceLocator.instance.audioManager.playButtonClick();
            Navigator.pushNamed(context, AppRoutes.settings);
          },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFB57C3E),
              Color(0xFF8B5A2B),
              Color(0xFF5D3A1A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF261205),
              offset: Offset(0, 2),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 2.5),
              blurRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
