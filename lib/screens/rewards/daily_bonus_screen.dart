import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_panel_modal.dart';
import '../../widgets/common/game_bottom_nav_bar.dart';
import '../../widgets/buttons/glossy_button.dart';

class DailyRewardDay {
  final int day;
  final String type; // 'coins', 'gems', 'chest'
  final int amount;
  final bool isClaimed;
  final bool isReady;

  const DailyRewardDay({
    required this.day,
    required this.type,
    required this.amount,
    required this.isClaimed,
    required this.isReady,
  });
}

class DailyBonusScreen extends StatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  int _currentStreak = 4; // Currently on Day 4
  bool _claimedToday = false;
  late Timer _timer;
  Duration _timeLeft = const Duration(hours: 12, minutes: 45, seconds: 20);

  final List<DailyRewardDay> _days = [
    const DailyRewardDay(day: 1, type: 'coins', amount: 100, isClaimed: true, isReady: false),
    const DailyRewardDay(day: 2, type: 'gems', amount: 5, isClaimed: true, isReady: false),
    const DailyRewardDay(day: 3, type: 'coins', amount: 150, isClaimed: true, isReady: false),
    const DailyRewardDay(day: 4, type: 'gems', amount: 10, isClaimed: false, isReady: true),
    const DailyRewardDay(day: 5, type: 'coins', amount: 200, isClaimed: false, isReady: false),
    const DailyRewardDay(day: 6, type: 'gems', amount: 15, isClaimed: false, isReady: false),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours}h ${minutes}m ${seconds}s';
  }

  void _claimDailyBonus() {
    if (_claimedToday) return;

    setState(() {
      _claimedToday = true;
    });

    final currentReward = _days[_currentStreak - 1];
    if (currentReward.type == 'coins') {
      ServiceLocator.instance.coinManager.addCoins(currentReward.amount);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Claimed Day $_currentStreak Reward: ${currentReward.amount} ${currentReward.type.toUpperCase()}! 🎉'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WoodPanelModal(
      title: 'Daily Bonus',
      subtitle: 'Come back every day and get bigger rewards!',
      activeTab: GameBottomTab.rewards,
      onClose: () => Navigator.pop(context),
      bottomButton: GlossyButton(
        text: _claimedToday ? 'Claimed' : 'Claim',
        color: _claimedToday ? GlossyButtonColor.blue : GlossyButtonColor.green,
        height: 52,
        fontSize: 18,
        onPressed: _claimedToday ? null : _claimDailyBonus,
      ),
      footerInfo: Text(
        'Resets in: ${_formatDuration(_timeLeft)}',
        style: const TextStyle(
          color: Color(0xFFFFE082),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Days 1 to 6 Grid (2 rows x 3 cols)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: _days.map((day) => _buildDayCard(day)).toList(),
          ),

          const SizedBox(height: 10),

          // Day 7 Highlight Chest Card
          _buildDay7Card(),
        ],
      ),
    );
  }

  Widget _buildDayCard(DailyRewardDay reward) {
    final isCurrent = reward.day == _currentStreak && !_claimedToday;
    final isDone = reward.isClaimed || (reward.day == _currentStreak && _claimedToday);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D1606),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFFFFD54F) : const Color(0xFF5D3A1A),
          width: isCurrent ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isCurrent)
            const BoxShadow(
              color: Color(0xFFFFB300),
              offset: Offset(0, 0),
              blurRadius: 6,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Day ${reward.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),

              // Icon
              if (reward.type == 'coins')
                Image.asset('assets/images/icons/icon_coin.png', width: 28, height: 28)
              else
                Image.asset('assets/images/icons/icon_gem.png', width: 28, height: 28),

              const SizedBox(height: 4),

              // Amount
              Text(
                '${reward.amount}',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          // Green Checkmark Badge if claimed
          if (isDone)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDay7Card() {
    return Container(
      width: double.infinity,
      height: 125,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1606), Color(0xFF42210B), Color(0xFF2D1606)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 2.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFFFA000),
            offset: Offset(0, 0),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Day 7 Label in top left
          const Positioned(
            top: 4,
            left: 8,
            child: Text(
              'Day 7',
              style: TextStyle(
                color: Color(0xFFFFECB3),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // Center Chest & Big Reward Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Image.asset(
                  'assets/images/home_screen/icon_chest_rewards.png',
                  height: 52,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Big Reward!',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
