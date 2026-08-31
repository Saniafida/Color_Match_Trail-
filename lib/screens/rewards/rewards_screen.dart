import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_panel_modal.dart';
import '../../widgets/common/game_bottom_nav_bar.dart';
import '../../widgets/buttons/glossy_button.dart';
import 'daily_bonus_screen.dart';

class QuestItem {
  final String id;
  final String title;
  final int current;
  final int target;
  final String rewardType; // 'coins', 'gems', 'bomb'
  final int rewardAmount;
  bool isClaimed;

  QuestItem({
    required this.id,
    required this.title,
    required this.current,
    required this.target,
    required this.rewardType,
    required this.rewardAmount,
    this.isClaimed = false,
  });

  bool get isCompleted => current >= target;
}

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final List<QuestItem> _quests = [
    QuestItem(
      id: 'quest_1',
      title: 'Complete 10 Moves',
      current: 10,
      target: 10,
      rewardType: 'coins',
      rewardAmount: 100,
    ),
    QuestItem(
      id: 'quest_2',
      title: 'Clear 3 Lines',
      current: 3,
      target: 3,
      rewardType: 'gems',
      rewardAmount: 10,
    ),
    QuestItem(
      id: 'quest_3',
      title: 'Score 5000 Points',
      current: 5000,
      target: 5000,
      rewardType: 'coins',
      rewardAmount: 200,
    ),
    QuestItem(
      id: 'quest_4',
      title: 'Use 2 Boosters',
      current: 2,
      target: 2,
      rewardType: 'bomb',
      rewardAmount: 15,
    ),
    QuestItem(
      id: 'quest_5',
      title: 'Play 1 Daily Challenge',
      current: 1,
      target: 1,
      rewardType: 'coins',
      rewardAmount: 150,
    ),
  ];

  void _claimReward(QuestItem quest) {
    if (quest.isClaimed) return;

    setState(() {
      quest.isClaimed = true;
    });

    // Credit coins / inventory
    if (quest.rewardType == 'coins') {
      ServiceLocator.instance.coinManager.addCoins(quest.rewardAmount);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Claimed ${quest.rewardAmount} ${quest.rewardType.toUpperCase()}! 🎉'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _claimAll() {
    int coinsToAdd = 0;
    int claimedCount = 0;

    setState(() {
      for (final q in _quests) {
        if (q.isCompleted && !q.isClaimed) {
          q.isClaimed = true;
          claimedCount++;
          if (q.rewardType == 'coins') {
            coinsToAdd += q.rewardAmount;
          }
        }
      }
    });

    if (coinsToAdd > 0) {
      ServiceLocator.instance.coinManager.addCoins(coinsToAdd);
    }

    if (claimedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claimed all available quest rewards! 🎉 (+$coinsToAdd Coins)'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnclaimed = _quests.any((q) => q.isCompleted && !q.isClaimed);

    return WoodPanelModal(
      title: 'Rewards',
      subtitle: 'Play games and win amazing rewards!',
      activeTab: GameBottomTab.rewards,
      onClose: () => Navigator.pop(context),
      bottomButton: GlossyButton(
        text: 'Claim All',
        color: hasUnclaimed ? GlossyButtonColor.green : GlossyButtonColor.gold,
        height: 52,
        fontSize: 18,
        onPressed: hasUnclaimed ? _claimAll : null,
      ),
      child: Column(
        children: [
          // Daily Bonus Shortcut Pill Banner
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyBonusScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFE65100)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFF59D), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '7-Day Login Bonus Available!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),

          // Quests List
          Expanded(
            child: ListView.separated(
              itemCount: _quests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final quest = _quests[index];
                return _buildQuestCard(quest);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(QuestItem quest) {
    final progressFraction = (quest.current / quest.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC), // Light parchment cream card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD7CCC8),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF2C1605),
            offset: Offset(0, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Task Title & Green Progress Bar
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),

                // Green Progress Bar with text inside
                Container(
                  height: 18,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFF81C784), width: 1.2),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progressFraction,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF81C784), Color(0xFF43A047), Color(0xFF2E7D32)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${quest.current}/${quest.target}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Center: Reward Icon & Amount
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRewardIcon(quest.rewardType),
                const SizedBox(height: 2),
                Text(
                  '${quest.rewardAmount}',
                  style: const TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Right: Claim Button
          Expanded(
            flex: 3,
            child: GlossyButton(
              text: quest.isClaimed ? 'Done' : 'Claim',
              color: quest.isClaimed ? GlossyButtonColor.blue : GlossyButtonColor.green,
              height: 38,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onPressed: (!quest.isClaimed && quest.isCompleted) ? () => _claimReward(quest) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardIcon(String type) {
    if (type == 'coins') {
      return Image.asset('assets/images/icons/icon_coin.png', width: 22, height: 22);
    } else if (type == 'gems') {
      return Image.asset('assets/images/icons/icon_gem.png', width: 22, height: 22);
    } else {
      return Image.asset('assets/images/boosters/bomb.png', width: 22, height: 22);
    }
  }
}
