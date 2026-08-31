import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../widgets/common/wood_panel_modal.dart';
import '../../widgets/common/game_bottom_nav_bar.dart';

class GameEventItem {
  final String title;
  final String description;
  final String timeLeft;
  final String iconPath;
  final List<Color> gradientColors;
  final String targetLevelId;

  const GameEventItem({
    required this.title,
    required this.description,
    required this.timeLeft,
    required this.iconPath,
    required this.gradientColors,
    required this.targetLevelId,
  });
}

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  final List<GameEventItem> _events = const [
    GameEventItem(
      title: 'Rainbow Rush',
      description: 'Clear as many tiles as you can!',
      timeLeft: '2d 14h',
      iconPath: 'assets/images/boosters/color_bomb.png',
      gradientColors: [Color(0xFF29B6F6), Color(0xFF0288D1), Color(0xFF01579B)],
      targetLevelId: 'level_1',
    ),
    GameEventItem(
      title: 'Star Tournament',
      description: 'Compete with other players!',
      timeLeft: '5d 21h',
      iconPath: 'assets/images/home_screen/icon_events_trophy.png',
      gradientColors: [Color(0xFF1976D2), Color(0xFF0D47A1), Color(0xFF1A237E)],
      targetLevelId: 'level_2',
    ),
    GameEventItem(
      title: 'Booster Blitz',
      description: 'Use boosters and earn points!',
      timeLeft: '1d 10h',
      iconPath: 'assets/images/boosters/hammer.png',
      gradientColors: [Color(0xFFAB47BC), Color(0xFF7B1FA2), Color(0xFF4A148C)],
      targetLevelId: 'level_3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return WoodPanelModal(
      title: 'Events',
      subtitle: 'Join events and win awesome rewards!',
      activeTab: GameBottomTab.events,
      onClose: () => Navigator.pop(context),
      child: Column(
        children: [
          // Event Cards List
          Expanded(
            child: ListView.separated(
              itemCount: _events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = _events[index];
                return _buildEventCard(context, event);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Bottom "More events coming soon!" banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1606).withAlpha(200),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration_rounded, color: Color(0xFFFFCA28), size: 18),
                SizedBox(width: 8),
                Text(
                  'More events coming soon!',
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.celebration_rounded, color: Color(0xFFFF7043), size: 18),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, GameEventItem event) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.gameplay, arguments: event.targetLevelId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: event.gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFFD54F),
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF102027),
              offset: Offset(0, 3.5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Event Graphic Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 3),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  event.iconPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Center: Title, Description, Timer Pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Timer Pill
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFFFFD54F), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        event.timeLeft,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right: Gift Box Reward Icon
            _buildGiftBoxIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftBoxIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 2),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical Gold Ribbon
          Container(
            width: 8,
            height: double.infinity,
            color: const Color(0xFFFFD54F),
          ),
          // Horizontal Gold Ribbon
          Container(
            height: 8,
            width: double.infinity,
            color: const Color(0xFFFFD54F),
          ),
          // Center Bow
          const Icon(Icons.star, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}
