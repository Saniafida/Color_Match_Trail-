import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_sign_header.dart';
import '../../widgets/buttons/glossy_button.dart';
import '../../widgets/dialogs/out_of_hearts_dialog.dart';
import '../../widgets/rewards/reward_popup.dart';
import '../../game/rewards/reward_definition.dart';
import '../../game/challenges/daily_challenge_definition.dart';
import '../../game/challenges/daily_challenge_progress.dart';
import '../../game/blocks/block_widget.dart';
import '../../models/models.dart' hide RewardType;

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final _manager = ServiceLocator.instance.dailyChallengeManager;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  static const List<Map<String, dynamic>> _weekDays = [
    {'day': 1, 'coins': 100, 'label': 'Day 1'},
    {'day': 2, 'coins': 150, 'label': 'Day 2'},
    {'day': 3, 'coins': 200, 'label': 'Day 3'},
    {'day': 4, 'coins': 250, 'label': 'Day 4'},
    {'day': 5, 'coins': 300, 'label': 'Day 5'},
    {'day': 6, 'coins': 350, 'label': 'Day 6'},
    {'day': 7, 'coins': 500, 'label': 'Day 7', 'isGrand': true},
  ];

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onStateChanged);
    _manager.initialize();
    _updateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTimeLeft();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _manager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      _timeLeft = tomorrow.difference(now);
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final mins = (d.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  Future<void> _handlePlay() async {
    final livesManager = ServiceLocator.instance.livesManager;
    if (!livesManager.hasLives) {
      final refilled = await OutOfHeartsDialog.show(context);
      if (!refilled || !livesManager.hasLives) return;
    }
    final levelToPlay = ServiceLocator.instance.progressionManager.state.currentLevel ?? 'level_1';
    if (mounted) {
      Navigator.pushNamed(context, AppRoutes.gameplay, arguments: levelToPlay);
    }
  }

  Future<void> _handleClaim() async {
    final challenge = _manager.currentChallenge;
    if (challenge == null) return;

    ServiceLocator.instance.audioManager.playButtonClick();
    final success = await _manager.claimReward();
    if (success && mounted) {
      final rewardDef = RewardDefinition(
        id: 'daily_${challenge.id}',
        type: challenge.rewardId == 'coins' ? RewardType.coins : RewardType.booster,
        amount: challenge.rewardAmount,
        itemId: challenge.rewardId == 'coins' ? null : challenge.rewardId,
        source: 'daily_challenge',
      );
      RewardPopup.show(context, [rewardDef]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _manager.currentChallenge;
    final progress = _manager.currentProgress;
    final int currentDay = _manager.currentDay;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Dark contrast overlay
          Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),

          // 3. Fully Responsive Content
          SafeArea(
            child: Column(
              children: [
                WoodSignHeader(
                  title: 'Daily Challenge',
                  onBack: () => Navigator.pop(context),
                ),

                // Unified SingleChildScrollView ensures NO vertical overflow on any device
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),

                        // Top Streak Pill & Reset Timer Row
                        _buildTopPillsRow(currentDay),

                        const SizedBox(height: 10),

                        // 7-Day Streak Wooden Container
                        _buildSevenDayContainer(currentDay),

                        const SizedBox(height: 12),

                        // Active Challenge Mission Card
                        if (challenge != null && progress != null)
                          _buildActiveMissionCard(challenge, progress, currentDay)
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: Colors.amber),
                            ),
                          ),

                        const SizedBox(height: 14),

                        // Bottom Action Buttons
                        _buildActionButtons(challenge),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Responsive Top Row with Streak and Countdown Timer
  Widget _buildTopPillsRow(int currentDay) {
    return Row(
      children: [
        // Streak pill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA000), Color(0xFFE65100)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
              boxShadow: const [
                BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.yellowAccent, size: 17),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Day $currentDay of 7 Streak',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Reset Timer pill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E1505).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC7A774), width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFFFFE082), size: 15),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Resets in: ${_formatDuration(_timeLeft)}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 7-Day Wooden Container with responsive header and horizontal scroll
  Widget _buildSevenDayContainer(int currentDay) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F), width: 3.0),
        boxShadow: const [
          BoxShadow(color: Color(0xFF261205), offset: Offset(0, 4), blurRadius: 0),
          BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: Color(0xFFFFD54F), size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '7-DAY REWARD ROAD',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            shadows: [
                              Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Day 7 = Grand Chest!',
                  style: TextStyle(
                    color: Colors.amber.shade200,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Day Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _weekDays.map((item) {
                final int day = item['day'] as int;
                final int coins = item['coins'] as int;
                final String label = item['label'] as String;
                final bool isGrand = item['isGrand'] as bool? ?? false;

                final bool isToday = day == currentDay;
                final bool isCompleted = day < currentDay || (isToday && _manager.isCompleted);
                final bool isActive = isToday && !_manager.isCompleted;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildDayCard(
                    dayNumber: day,
                    dayTitle: label,
                    coins: coins.toString(),
                    isCompleted: isCompleted,
                    isActive: isActive,
                    isGrand: isGrand,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Day Card (Day 1 through Day 7)
  Widget _buildDayCard({
    required int dayNumber,
    required String dayTitle,
    required String coins,
    required bool isCompleted,
    required bool isActive,
    required bool isGrand,
  }) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFFFFBE8), Color(0xFFFFEDAA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : isGrand
                ? const LinearGradient(
                    colors: [Color(0xFF5D2E14), Color(0xFF381A0B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF4A250B), Color(0xFF2C1506)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFFD54F)
              : isGrand
                  ? const Color(0xFFFFA000)
                  : const Color(0xFF8D6E63),
          width: isActive ? 2.5 : (isGrand ? 2.0 : 1.4),
        ),
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Color(0x66FFD54F),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day Header
          Text(
            dayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF3E200C)
                  : (isGrand ? const Color(0xFFFFE082) : const Color(0xFFD7CCC8)),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),

          // Status Icon / Badge
          if (isCompleted)
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 18),
            )
          else if (isActive)
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFE082), Color(0xFFFFA000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x44FFA000), offset: Offset(0, 2), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
            )
          else if (isGrand)
            const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD54F), size: 26)
          else
            const Icon(Icons.lock_rounded, color: Colors.white38, size: 22),

          const SizedBox(height: 5),

          // Reward Coins
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/icons/icon_coin.png',
                width: 13,
                height: 13,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 13),
              ),
              const SizedBox(width: 3),
              Text(
                coins,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFFD84315)
                      : (isGrand ? const Color(0xFFFFE082) : Colors.white70),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Today's Active Mission Card
  Widget _buildActiveMissionCard(
    DailyChallengeDefinition challenge,
    DailyChallengeProgress progress,
    int currentDay,
  ) {
    final bool isCompleted = _manager.isCompleted;
    final bool isClaimed = _manager.isRewardClaimed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F), width: 3.0),
        boxShadow: const [
          BoxShadow(color: Color(0xFF261205), offset: Offset(0, 4), blurRadius: 0),
          BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 8),
        ],
      ),
      child: Container(
        // Inner Parchment / Cream Card Box
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFFDF5),
              Color(0xFFFBF1DB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5D2A6), width: 1.8),
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Header Row: Mission Title & Status
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Color(0xFF8D5325), size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "TODAY'S MISSION (DAY $currentDay)",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color(0xFF3E200C),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade100 : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.amber.shade800,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    isClaimed
                        ? 'CLAIMED'
                        : isCompleted
                            ? 'COMPLETED!'
                            : 'IN PROGRESS',
                    style: TextStyle(
                      color: isCompleted ? Colors.green.shade800 : Colors.amber.shade900,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Instruction subtitle
            const Text(
              'Clear the required blocks in any level to complete this mission:',
              style: TextStyle(
                color: Color(0xFF7A4E24),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            // Target 1: Primary Color
            _buildGoalRow(
              color: challenge.primaryColor,
              current: progress.currentValue,
              target: challenge.primaryTarget,
            ),

            const SizedBox(height: 8),

            // Target 2: Secondary Color
            _buildGoalRow(
              color: challenge.secondaryColor,
              current: progress.currentValue2,
              target: challenge.secondaryTarget,
            ),

            const SizedBox(height: 12),

            // Reward Capsule Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E7C4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCC196), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Mission Reward:',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF5D3312),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/icons/icon_coin.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${challenge.rewardAmount} Coins',
                        style: const TextStyle(
                          color: Color(0xFFD84315),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single Goal Row with Block Widget, Label, Count, and Progress Bar
  Widget _buildGoalRow({
    required BlockColor color,
    required int current,
    required int target,
  }) {
    final bool isDone = current >= target;
    final double percent = (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? Colors.green.shade400 : const Color(0xFFE5D2A6),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          // 3D Block
          BlockWidget(
            block: Block(
              id: 'challenge_${color.name}',
              color: color,
              position: const Position(0, 0),
            ),
            size: 32,
          ),
          const SizedBox(width: 10),

          // Progress Title and Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "${color.name.toUpperCase()} BLOCKS",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: isDone ? Colors.green.shade800 : const Color(0xFF3E200C),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$current / $target",
                      style: TextStyle(
                        color: isDone ? Colors.green.shade800 : const Color(0xFF7A4E24),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE8DFC8),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? const Color(0xFF43A047) : const Color(0xFFFFA000),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Checkmark
          if (isDone)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 20)
          else
            Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }

  /// Responsive Dynamic Bottom Action Buttons
  Widget _buildActionButtons(DailyChallengeDefinition? challenge) {
    if (challenge == null) return const SizedBox.shrink();

    final bool isClaimed = _manager.isRewardClaimed;
    final bool canClaim = _manager.canClaimReward;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: canClaim
          ? GlossyButton(
              text: 'CLAIM REWARD',
              color: GlossyButtonColor.gold,
              height: 52,
              fontSize: 19,
              icon: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22),
              onPressed: _handleClaim,
            )
          : isClaimed
              ? Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'DONE TODAY!',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlossyButton(
                        text: 'PLAY MORE',
                        color: GlossyButtonColor.green,
                        height: 48,
                        fontSize: 15,
                        onPressed: _handlePlay,
                      ),
                    ),
                  ],
                )
              : GlossyButton(
                  text: 'PLAY NOW',
                  color: GlossyButtonColor.green,
                  height: 52,
                  fontSize: 19,
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  onPressed: _handlePlay,
                ),
    );
  }
}
