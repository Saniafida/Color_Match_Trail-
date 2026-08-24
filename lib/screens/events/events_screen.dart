import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_sign_header.dart';
import '../../widgets/buttons/glossy_button.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _manager = ServiceLocator.instance.eventManager;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _manager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Overlay
          Container(
            color: Colors.black.withAlpha(50),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                WoodSignHeader(
                  title: 'Events',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildEventCard(
                        title: 'Rainbow Rush',
                        subtitle: 'Clear colors and win amazing rewards!',
                        timeLeft: '2d 14h',
                        assetPath: 'assets/images/boosters/color_bomb.png',
                        onPlay: () {
                          Navigator.pushNamed(context, AppRoutes.gameplay, arguments: 'level_1');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildEventCard(
                        title: 'Star Tournament',
                        subtitle: 'Compete and be the champion!',
                        timeLeft: '5d 21h',
                        assetPath: 'assets/images/icons/icon_star_gold.png',
                        onPlay: () {
                          Navigator.pushNamed(context, AppRoutes.gameplay, arguments: 'level_2');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String subtitle,
    required String timeLeft,
    required String assetPath,
    required VoidCallback onPlay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3C72).withAlpha(230), // Deep blue glossy card
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF0D1B2A),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black38,
            offset: Offset(0, 6),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Event Icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD54F), width: 2.0),
            ),
            child: ClipOval(
              child: Image.asset(assetPath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),

          // Title, Subtitle, Timer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFFFCA28), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      timeLeft,
                      style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Play Button
          GlossyButton(
            text: 'Play',
            color: GlossyButtonColor.green,
            height: 42,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
