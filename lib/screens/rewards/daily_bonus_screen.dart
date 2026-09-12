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
  int _currentStreak = 1;
  bool _claimedToday = false;
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  static const List<DailyRewardDay> _baseDays = [
    DailyRewardDay(day: 1, type: 'coins', amount: 100, isClaimed: false, isReady: false),
    DailyRewardDay(day: 2, type: 'gems', amount: 5, isClaimed: false, isReady: false),
    DailyRewardDay(day: 3, type: 'coins', amount: 150, isClaimed: false, isReady: false),
    DailyRewardDay(day: 4, type: 'gems', amount: 10, isClaimed: false, isReady: false),
    DailyRewardDay(day: 5, type: 'coins', amount: 200, isClaimed: false, isReady: false),
    DailyRewardDay(day: 6, type: 'gems', amount: 15, isClaimed: false, isReady: false),
  ];

  @override
  void initState() {
    super.initState();
    _initDailyBonusState();
    _startTimer();
  }

  void _initDailyBonusState() {
    try {
      final dateService = ServiceLocator.instance.dateService;
      final todayKey = dateService.getTodayDateKey();
      final stats = ServiceLocator.instance.gameSaveManager.playerData.statistics;

      final lastClaimedDate = stats['daily_bonus_last_claimed_date'] as String?;
      final savedStreak = (stats['daily_bonus_streak'] as num?)?.toInt() ?? 1;

      if (lastClaimedDate == null || lastClaimedDate.isEmpty) {
        // First time opening / playing -> Start on Day 1
        _currentStreak = 1;
        _claimedToday = false;
      } else if (lastClaimedDate == todayKey) {
        // Already claimed today
        _currentStreak = savedStreak.clamp(1, 7);
        _claimedToday = true;
      } else {
        // Claimed on a previous date
        final lastDate = _parseDateKey(lastClaimedDate);
        final todayDate = dateService.now();

        if (lastDate != null) {
          final diffDays = _calendarDaysBetween(lastDate, todayDate);
          if (diffDays == 1) {
            // Consecutive day login: advance streak
            _currentStreak = (savedStreak >= 7) ? 1 : savedStreak + 1;
            _claimedToday = false;
          } else if (diffDays > 1) {
            // Missed days: reset to Day 1
            _currentStreak = 1;
            _claimedToday = false;
          } else {
            // Negative difference (clock adjustment): keep claimed
            _currentStreak = savedStreak.clamp(1, 7);
            _claimedToday = true;
          }
        } else {
          _currentStreak = 1;
          _claimedToday = false;
        }
      }
    } catch (_) {
      _currentStreak = 1;
      _claimedToday = false;
    }
  }

  DateTime? _parseDateKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
  }

  int _calendarDaysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  Duration _calculateTimeUntilTomorrow() {
    try {
      final now = ServiceLocator.instance.dateService.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final diff = tomorrow.difference(now);
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final diff = tomorrow.difference(now);
      return diff.isNegative ? Duration.zero : diff;
    }
  }

  void _startTimer() {
    _timeLeft = _calculateTimeUntilTomorrow();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _calculateTimeUntilTomorrow();
      if (remaining.inSeconds <= 0) {
        setState(() {
          _initDailyBonusState();
          _timeLeft = _calculateTimeUntilTomorrow();
        });
      } else {
        setState(() {
          _timeLeft = remaining;
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
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m ${seconds}s';
  }

  List<DailyRewardDay> get _days {
    return _baseDays.map((base) {
      final isDone = base.day < _currentStreak || (base.day == _currentStreak && _claimedToday);
      final isReady = base.day == _currentStreak && !_claimedToday;
      return DailyRewardDay(
        day: base.day,
        type: base.type,
        amount: base.amount,
        isClaimed: isDone,
        isReady: isReady,
      );
    }).toList();
  }

  DailyRewardDay _getRewardForCurrentDay() {
    if (_currentStreak >= 1 && _currentStreak <= 6) {
      return _days[_currentStreak - 1];
    }
    return const DailyRewardDay(
      day: 7,
      type: 'chest',
      amount: 500,
      isClaimed: false,
      isReady: true,
    );
  }

  void _claimDailyBonus() {
    if (_claimedToday) return;

    final currentReward = _getRewardForCurrentDay();

    try {
      final todayKey = ServiceLocator.instance.dateService.getTodayDateKey();
      final saveManager = ServiceLocator.instance.gameSaveManager;
      final stats = Map<String, dynamic>.from(saveManager.playerData.statistics);
      stats['daily_bonus_streak'] = _currentStreak;
      stats['daily_bonus_last_claimed_date'] = todayKey;
      saveManager.updateStatistics(stats);
      saveManager.saveNow();
    } catch (_) {}

    setState(() {
      _claimedToday = true;
    });

    if (currentReward.type == 'coins') {
      ServiceLocator.instance.coinManager.addCoins(currentReward.amount);
    } else if (currentReward.type == 'gems') {
      ServiceLocator.instance.gemManager.addGems(currentReward.amount);
    } else if (currentReward.type == 'chest') {
      ServiceLocator.instance.coinManager.addCoins(500);
      ServiceLocator.instance.gemManager.addGems(20);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentReward.type == 'chest'
              ? 'Claimed Day 7 Chest: 500 COINS + 20 GEMS! 🎉'
              : 'Claimed Day $_currentStreak Reward: ${currentReward.amount} ${currentReward.type.toUpperCase()}! 🎉',
        ),
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
        color: _claimedToday ? GlossyButtonColor.wood : GlossyButtonColor.green,
        height: 52,
        fontSize: 18,
        onPressed: _claimedToday ? null : _claimDailyBonus,
      ),
      footerInfo: Text(
        _claimedToday
            ? 'Come back tomorrow! Resets in: ${_formatDuration(_timeLeft)}'
            : 'Resets in: ${_formatDuration(_timeLeft)}',
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
    final isDone = reward.isClaimed;

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
    final isCurrent = _currentStreak == 7 && !_claimedToday;
    final isDone = _currentStreak == 7 && _claimedToday;

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
          color: isCurrent ? const Color(0xFFFFE082) : const Color(0xFFFFD54F),
          width: isCurrent ? 3.0 : 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent ? const Color(0xFFFFD54F) : const Color(0xFFFFA000),
            offset: const Offset(0, 0),
            blurRadius: isCurrent ? 12 : 8,
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

          // Green Checkmark Badge if Day 7 is claimed
          if (isDone)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
