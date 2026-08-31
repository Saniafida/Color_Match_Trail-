import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../achievements/widgets/achievement_unlock_popup.dart';
import '../achievements/widgets/milestone_unlock_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadProgress();
    try {
      ServiceLocator.instance.audioManager.playHomeBgm();
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AchievementUnlockOverlay.initialize(context);
      MilestoneUnlockOverlay.initialize(context);
    });
  }

  void _loadProgress() {
    try {
      final progressionManager = ServiceLocator.instance.progressionManager;
      progressionManager.initialize();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _onPlay() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.worldMap,
    );
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final coinManager = ServiceLocator.instance.coinManager;
    final coins = coinManager.balance;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Subtle Vignette
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withAlpha(40),
                  Colors.transparent,
                  Colors.black.withAlpha(50),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Scrollable Main Layout with Responsive Padding
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              child: Column(
                children: [
                  // Top HUD: Hearts, Coins, Gems, Settings
                  _buildTopHudBar(coins),

                  const SizedBox(height: 6),

                  // TOP HERO SECTION: Floating Rewards (Left), Wood Logo + Baby Bear (Center), Daily Bonus (Right)
                  _buildHeroLogoSection(),

                  const SizedBox(height: 8),

                  // BIG GLOSSY GREEN "PLAY" BUTTON
                  _buildPlayButton(),

                  const SizedBox(height: 10),

                  // 2 MAIN FEATURE CARDS (Daily Challenge & Events)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Daily Challenge Card (Blue)
                        Expanded(
                          child: _buildFeatureCard(
                            title: 'Daily Challenge',
                            subtitle: 'Complete daily puzzles and win amazing rewards!',
                            badgeWidget: _buildCalendarBadge(),
                            colorGradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5), Color(0xFF1565C0)],
                            borderColor: const Color(0xFF90CAF9),
                            hasProgressBar: true,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.challenges),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. Events Card (Purple)
                        Expanded(
                          child: _buildFeatureCard(
                            title: 'Events',
                            subtitle: 'Join exciting events and win awesome prizes!',
                            badgeWidget: Image.asset(
                              'assets/images/home_screen/icon_events_trophy.png',
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                            ),
                            colorGradient: const [Color(0xFFAB47BC), Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                            borderColor: const Color(0xFFCE93D8),
                            hasProgressBar: false,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.events),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ⭐ MINI GAMES ⭐ WOODEN PANEL
                  _buildMiniGamesPanel(),

                  const SizedBox(height: 12),

                  // BOTTOM 5 WOODEN NAVIGATION BUTTONS (Shop, Friends, Spin, Pass, Inbox)
                  _buildBottomNavBar(),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🏆 TOP HUD STAT BAR
  // ==========================================
  Widget _buildTopHudBar(int coins) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: SizedBox(
        width: 360,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Hearts Pill (5 Full +)
            _buildStatPill(
              iconPath: 'assets/images/icons/icon_heart.png',
              value: '5',
              subLabel: 'Full',
            ),

            // 2. Coins Pill (1250 +)
            _buildStatPill(
              iconPath: 'assets/images/icons/icon_coin.png',
              value: '$coins',
            ),

            // 3. Gems Pill (230 +)
            _buildStatPill(
              iconPath: 'assets/images/icons/icon_gem.png',
              value: '230',
            ),

            // 4. Settings Gear Button
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D4C41), Color(0xFF4E342E), Color(0xFF3E2723)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 2.0),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1B0D05), offset: Offset(0, 3), blurRadius: 0),
                    BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 4),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.settings, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required String iconPath,
    required String value,
    String? subLabel,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.fromLTRB(3, 2, 4, 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 3),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 24, height: 24, fit: BoxFit.contain),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF3E200C),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(width: 3),
            Text(
              subLabel,
              style: const TextStyle(
                color: Color(0xFF5D3A1A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(width: 4),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: Colors.white, width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0xFF1B5E20), offset: Offset(0, 1), blurRadius: 0),
              ],
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🌟 TOP HERO SECTION: REWARDS, WOOD LOGO & DAILY BONUS
  // ==========================================
  Widget _buildHeroLogoSection() {
    return SizedBox(
      height: 195,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Center 3D Wooden Logo
          Positioned(
            top: 0,
            child: Image.asset(
              'assets/images/logo_wood.png',
              height: 155,
              fit: BoxFit.contain,
            ),
          ),

          // 2. 3D Mascot Bear with Toy Blocks (leaning in from left)
          Positioned(
            left: 2,
            bottom: 0,
            child: Image.asset(
              'assets/images/home_screen/mascot_bear_play.png',
              height: 130,
              fit: BoxFit.contain,
            ),
          ),

          // 3. Top-Left Floating Button: Rewards (with chest & badge '2')
          Positioned(
            left: 2,
            top: 2,
            child: _buildTopBadgeButton(
              label: 'Rewards',
              imagePath: 'assets/images/home_screen/icon_chest_rewards.png',
              badgeText: '2',
              onTap: () => Navigator.pushNamed(context, AppRoutes.rewards),
            ),
          ),

          // 4. Top-Right Floating Button: Daily Bonus (with green gift & badge '!')
          Positioned(
            right: 2,
            top: 2,
            child: _buildTopBadgeButton(
              label: 'Daily Bonus',
              imagePath: 'assets/images/home_screen/icon_daily_bonus.png',
              badgeText: '!',
              onTap: () => Navigator.pushNamed(context, AppRoutes.dailyBonus),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadgeButton({
    required String label,
    required String imagePath,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8D5325), Color(0xFF6B3C17), Color(0xFF4E2A0E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
              boxShadow: const [
                BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 3), blurRadius: 0),
                BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(imagePath, width: 34, height: 34, fit: BoxFit.contain),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Red notification badge
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
                ],
              ),
              child: Center(
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🟢 VIBRANT GLOSSY GREEN PLAY BUTTON
  // ==========================================
  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _onPlay,
      child: Container(
        width: double.infinity,
        height: 58,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8CE03E), Color(0xFF64BD1A), Color(0xFF439906)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFA5F062), width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF286403),
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 6),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Play',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              shadows: [
                Shadow(color: Color(0xFF1E5002), offset: Offset(0, 2), blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🔵 GLOSSY FEATURE CARD (Daily Challenge & Events) - COMPACT & SLEEK
  // ==========================================
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required Widget badgeWidget,
    required List<Color> colorGradient,
    required Color borderColor,
    required bool hasProgressBar,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        constraints: const BoxConstraints(minHeight: 68),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colorGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: colorGradient.last.withAlpha(200),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            const BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Icon Badge
                badgeWidget,
                const SizedBox(width: 5),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow '>'
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ],
            ),

            if (hasProgressBar) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D47A1).withAlpha(150),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: 3 / 7,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          const Center(
                            child: Text(
                              '⭐ 3/7',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/images/home_screen/icon_chest_rewards.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE53935), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            height: 7,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '23',
                style: TextStyle(
                  color: Color(0xFF3E200C),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ⭐ MINI GAMES WOODEN PANEL (Tile Sort, Tile Stack, Tile Drop, Tile Swap)
  // ==========================================
  Widget _buildMiniGamesPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(6, 26, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF633A18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF8D5325), width: 4.0),
        boxShadow: const [
          BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 6), blurRadius: 0),
          BoxShadow(color: Colors.black45, offset: Offset(0, 8), blurRadius: 8),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 4 Mini Games Cards Row
          Row(
            children: [
              Expanded(
                child: _buildMiniGameCard(
                  title: 'TILE SORT',
                  subtitle: 'Sort tiles\nby color',
                  headerColor: const Color(0xFF1E88E5),
                  imagePath: 'assets/images/home_screen/mini_tile_sort.png',
                  onPlay: () => Navigator.pushNamed(context, AppRoutes.tileSort),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildMiniGameCard(
                  title: 'TILE STACK',
                  subtitle: 'Stack same tiles\nto clear them',
                  headerColor: const Color(0xFF8E24AA),
                  imagePath: 'assets/images/home_screen/mini_tile_stack.png',
                  onPlay: () => Navigator.pushNamed(context, AppRoutes.tileStack),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildMiniGameCard(
                  title: 'TILE DROP',
                  subtitle: 'Drop tiles and\nmatch colors',
                  headerColor: const Color(0xFFFB8C00),
                  imagePath: 'assets/images/home_screen/mini_tile_drop.png',
                  onPlay: () => Navigator.pushNamed(context, AppRoutes.tileDrop),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildMiniGameCard(
                  title: 'TILE SWAP',
                  subtitle: 'Swap tiles to\nmake matches',
                  headerColor: const Color(0xFF43A047),
                  imagePath: 'assets/images/home_screen/mini_tile_swap.png',
                  onPlay: () => Navigator.pushNamed(context, AppRoutes.tileSwap),
                ),
              ),
            ],
          ),

          // ⭐ MINI GAMES ⭐ Wooden Sign Header
          Positioned(
            top: -42,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D5325), Color(0xFF5D3512)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD54F), width: 2.0),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF2C1605), offset: Offset(0, 3), blurRadius: 0),
                  BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 4),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 17),
                  SizedBox(width: 4),
                  Text(
                    'MINI GAMES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(color: Colors.black87, offset: Offset(0, 1.5), blurRadius: 2),
                      ],
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGameCard({
    required String title,
    required String subtitle,
    required Color headerColor,
    required String imagePath,
    required VoidCallback onPlay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7E8CE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2CCAE), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3),
        ],
      ),
      child: Column(
        children: [
          // Top Title Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          // Screenshot Preview
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                height: 60,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Subtitle text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: SizedBox(
              height: 22,
              child: Center(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Color(0xFF5D3A1A),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Mini Glossy Play Button
          GestureDetector(
            onTap: onPlay,
            child: Container(
              margin: const EdgeInsets.fromLTRB(4, 0, 4, 5),
              height: 22,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8CE03E), Color(0xFF53A810)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFA5F062), width: 1.0),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF286403), offset: Offset(0, 1.5), blurRadius: 0),
                ],
              ),
              child: const Center(
                child: Text(
                  'Play',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🪵 BOTTOM 5 WOODEN NAVIGATION BUTTONS (Shop, Friends, Spin, Pass, Inbox) - RESPONSIVE
  // ==========================================
  Widget _buildBottomNavBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Shop
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildBottomNavButton(
              label: 'Shop',
              iconWidget: _buildShopAwningIcon(),
              onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
            ),
          ),
        ),

        // 2. Achievements
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildBottomNavButton(
              label: 'Achievements',
              iconWidget: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 24),
              onTap: () => Navigator.pushNamed(context, AppRoutes.achievements),
            ),
          ),
        ),

        // 3. Spin
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildBottomNavButton(
              label: 'Spin',
              iconWidget: _buildSpinWheelIcon(),
              onTap: () => Navigator.pushNamed(context, AppRoutes.spinWheel),
            ),
          ),
        ),

        // 4. Events
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildBottomNavButton(
              label: 'Events',
              iconWidget: Image.asset(
                'assets/images/home_screen/icon_pass_shield.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.events),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavButton({
    required String label,
    required Widget iconWidget,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 62,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8D5325), Color(0xFF6B3C17), Color(0xFF4E2A0E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF2C1605),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black38,
                  offset: Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (badgeText != null)
            Positioned(
              top: -4,
              right: -3,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
                  ],
                ),
                child: Center(
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Shop Tent Awning Icon
  Widget _buildShopAwningIcon() {
    return Container(
      width: 26,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF8D5325), width: 1),
      ),
      child: Column(
        children: [
          Container(
            height: 7,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE53935), Color(0xFFFFF9EC),
                  Color(0xFFE53935), Color(0xFFFFF9EC),
                  Color(0xFFE53935),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Icon(Icons.storefront_rounded, color: Color(0xFF1E88E5), size: 13),
            ),
          ),
        ],
      ),
    );
  }

  // 3D Multicolor Spin Wheel
  Widget _buildSpinWheelIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
        ],
        gradient: const SweepGradient(
          colors: [
            Color(0xFFE91E63),
            Color(0xFFFFEB3B),
            Color(0xFF00E676),
            Color(0xFF29B6F6),
            Color(0xFFFF9800),
            Color(0xFFE91E63),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
