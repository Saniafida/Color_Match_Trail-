import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../models/booster.dart';
import '../../widgets/common/wood_panel_modal.dart';
import '../../widgets/common/game_bottom_nav_bar.dart';
import '../../widgets/buttons/glossy_button.dart';

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
  List<QuestItem> _quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    final statsManager = ServiceLocator.instance.statisticsManager;
    final progressionManager = ServiceLocator.instance.progressionManager;
    final claimStore = ServiceLocator.instance.rewardClaimStore;

    final stats = statsManager.stats;
    final levelsDone = stats.levelsCompleted > progressionManager.state.levels.length
        ? stats.levelsCompleted
        : progressionManager.state.levels.length;

    final questsData = [
      {
        'id': 'quest_1',
        'title': 'Complete 3 Levels',
        'current': levelsDone,
        'target': 3,
        'rewardType': 'coins',
        'rewardAmount': 150,
      },
      {
        'id': 'quest_2',
        'title': 'Clear 50 Blocks',
        'current': stats.totalBlocksCleared,
        'target': 50,
        'rewardType': 'gems',
        'rewardAmount': 2,
      },
      {
        'id': 'quest_3',
        'title': 'Score 5,000 Points',
        'current': stats.highestScore,
        'target': 5000,
        'rewardType': 'coins',
        'rewardAmount': 200,
      },
      {
        'id': 'quest_4',
        'title': 'Use 2 Boosters',
        'current': stats.totalBoostersUsed,
        'target': 2,
        'rewardType': 'bomb',
        'rewardAmount': 1,
      },
      {
        'id': 'quest_5',
        'title': 'Play 1 Daily Challenge',
        'current': stats.totalDailyChallenges,
        'target': 1,
        'rewardType': 'gems',
        'rewardAmount': 3,
      },
    ];

    final List<QuestItem> loaded = [];
    for (final q in questsData) {
      final id = q['id'] as String;
      final isClaimed = await claimStore.hasClaimed(id);
      loaded.add(
        QuestItem(
          id: id,
          title: q['title'] as String,
          current: q['current'] as int,
          target: q['target'] as int,
          rewardType: q['rewardType'] as String,
          rewardAmount: q['rewardAmount'] as int,
          isClaimed: isClaimed,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _quests = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _claimReward(QuestItem quest) async {
    if (quest.isClaimed || !quest.isCompleted) return;

    setState(() {
      quest.isClaimed = true;
    });

    try {
      await ServiceLocator.instance.rewardClaimStore.markClaimed(quest.id);
    } catch (_) {}

    // Credit coins / gems / booster
    if (quest.rewardType == 'coins') {
      await ServiceLocator.instance.coinManager.addCoins(quest.rewardAmount);
    } else if (quest.rewardType == 'gems') {
      await ServiceLocator.instance.gemManager.addGems(quest.rewardAmount);
    } else if (quest.rewardType == 'bomb') {
      await ServiceLocator.instance.inventoryManager.addBooster(BoosterType.areaBlast, quest.rewardAmount);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Claimed +${quest.rewardAmount} ${quest.rewardType.toUpperCase()}! 🎉',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _claimAll() async {
    int coinsToAdd = 0;
    int gemsToAdd = 0;
    int claimedCount = 0;

    for (final q in _quests) {
      if (q.isCompleted && !q.isClaimed) {
        q.isClaimed = true;
        claimedCount++;
        try {
          await ServiceLocator.instance.rewardClaimStore.markClaimed(q.id);
        } catch (_) {}

        if (q.rewardType == 'coins') {
          coinsToAdd += q.rewardAmount;
        } else if (q.rewardType == 'gems') {
          gemsToAdd += q.rewardAmount;
        } else if (q.rewardType == 'bomb') {
          await ServiceLocator.instance.inventoryManager.addBooster(BoosterType.areaBlast, q.rewardAmount);
        }
      }
    }

    if (coinsToAdd > 0) {
      await ServiceLocator.instance.coinManager.addCoins(coinsToAdd);
    }
    if (gemsToAdd > 0) {
      await ServiceLocator.instance.gemManager.addGems(gemsToAdd);
    }

    if (mounted) {
      setState(() {});
      if (claimedCount > 0) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Claimed all quest rewards! 🎉 (+$coinsToAdd Coins, +$gemsToAdd Gems)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
        height: 50,
        fontSize: 17,
        onPressed: hasUnclaimed ? _claimAll : null,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD54F)))
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 6),
              itemCount: _quests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final quest = _quests[index];
                return _buildQuestCard(quest);
              },
            ),
    );
  }

  Widget _buildQuestCard(QuestItem quest) {
    final progressFraction = quest.target > 0
        ? (quest.current / quest.target).clamp(0.0, 1.0)
        : 0.0;
    final isReadyToClaim = quest.isCompleted && !quest.isClaimed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC), // Light parchment cream card
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReadyToClaim ? const Color(0xFFFFD54F) : const Color(0xFFD7CCC8),
          width: isReadyToClaim ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (isReadyToClaim)
            const BoxShadow(
              color: Color(0xFFFFD54F),
              offset: Offset(0, 0),
              blurRadius: 4,
            ),
          const BoxShadow(
            color: Color(0xFF2C1605),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Task Title & Progress Bar
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quest.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),

                // Progress Bar with progress text inside
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7CCC8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 1.0),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progressFraction,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: quest.isCompleted
                                  ? const [Color(0xFF81C784), Color(0xFF43A047), Color(0xFF2E7D32)]
                                  : const [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${quest.current.clamp(0, quest.target)}/${quest.target}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Center: Reward Icon & Amount
          SizedBox(
            width: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRewardIcon(quest.rewardType),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '+${quest.rewardAmount}',
                    style: const TextStyle(
                      color: Color(0xFF3E200C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Right: Claim Button
          SizedBox(
            width: 70,
            child: GlossyButton(
              text: quest.isClaimed
                  ? 'Claimed'
                  : (quest.isCompleted ? 'Claim' : 'Claim'),
              color: quest.isClaimed
                  ? GlossyButtonColor.blue
                  : (quest.isCompleted ? GlossyButtonColor.green : GlossyButtonColor.gold),
              height: 34,
              fontSize: 12,
              borderRadius: 10,
              padding: EdgeInsets.zero,
              onPressed: isReadyToClaim ? () => _claimReward(quest) : null,
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
