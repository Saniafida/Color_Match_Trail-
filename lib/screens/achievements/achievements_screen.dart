import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_sign_header.dart';
import '../../widgets/buttons/glossy_button.dart';

class AchievementItem {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color iconColor;
  final int current;
  final int target;
  final int coinsReward;
  final int gemsReward;
  bool isClaimed;

  AchievementItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.iconColor,
    required this.current,
    required this.target,
    required this.coinsReward,
    required this.gemsReward,
    this.isClaimed = false,
  });

  bool get isCompleted => current >= target;
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<AchievementItem> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final stats = ServiceLocator.instance.statisticsManager.stats;
    final progression = ServiceLocator.instance.progressionManager;
    final claimStore = ServiceLocator.instance.rewardClaimStore;

    final levelsCompleted = stats.levelsCompleted > progression.state.levels.length
        ? stats.levelsCompleted
        : progression.state.levels.length;

    final starsEarned = stats.totalStars > progression.totalStars
        ? stats.totalStars
        : progression.totalStars;

    final itemsData = [
      {
        'id': 'ach_levels_5',
        'title': 'Beginner Adventurer',
        'desc': 'Complete 5 levels',
        'icon': Icons.emoji_events_rounded,
        'iconColor': const Color(0xFFAB47BC),
        'current': levelsCompleted,
        'target': 5,
        'coins': 100,
        'gems': 2,
      },
      {
        'id': 'ach_stars_15',
        'title': 'Master Collector',
        'desc': 'Collect 15 stars across levels',
        'icon': Icons.star_rounded,
        'iconColor': const Color(0xFFFFB300),
        'current': starsEarned,
        'target': 15,
        'coins': 150,
        'gems': 3,
      },
      {
        'id': 'ach_blocks_100',
        'title': 'Block Buster',
        'desc': 'Destroy 100 blocks',
        'icon': Icons.grid_view_rounded,
        'iconColor': const Color(0xFF00ACC1),
        'current': stats.totalBlocksCleared,
        'target': 100,
        'coins': 200,
        'gems': 4,
      },
      {
        'id': 'ach_combo_5',
        'title': 'Combo King',
        'desc': 'Achieve a 5x Combo streak',
        'icon': Icons.local_fire_department_rounded,
        'iconColor': const Color(0xFFFF7043),
        'current': stats.highestCombo,
        'target': 5,
        'coins': 250,
        'gems': 5,
      },
      {
        'id': 'ach_boosters_5',
        'title': 'Booster Expert',
        'desc': 'Use 5 boosters in gameplay',
        'icon': Icons.auto_awesome_rounded,
        'iconColor': const Color(0xFF43A047),
        'current': stats.totalBoostersUsed,
        'target': 5,
        'coins': 150,
        'gems': 3,
      },
      {
        'id': 'ach_daily_3',
        'title': 'Daily Champion',
        'desc': 'Complete 3 Daily Challenges',
        'icon': Icons.calendar_today_rounded,
        'iconColor': const Color(0xFFE53935),
        'current': stats.totalDailyChallenges,
        'target': 3,
        'coins': 300,
        'gems': 6,
      },
    ];

    final List<AchievementItem> loaded = [];
    for (final item in itemsData) {
      final id = item['id'] as String;
      final isClaimed = await claimStore.hasClaimed(id);
      loaded.add(
        AchievementItem(
          id: id,
          title: item['title'] as String,
          desc: item['desc'] as String,
          icon: item['icon'] as IconData,
          iconColor: item['iconColor'] as Color,
          current: item['current'] as int,
          target: item['target'] as int,
          coinsReward: item['coins'] as int,
          gemsReward: item['gems'] as int,
          isClaimed: isClaimed,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _achievements = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _claimAchievement(AchievementItem item) async {
    if (item.isClaimed || !item.isCompleted) return;

    setState(() {
      item.isClaimed = true;
    });

    try {
      await ServiceLocator.instance.rewardClaimStore.markClaimed(item.id);
    } catch (_) {}

    // Credit coins & gems
    if (item.coinsReward > 0) {
      await ServiceLocator.instance.coinManager.addCoins(item.coinsReward);
    }
    if (item.gemsReward > 0) {
      await ServiceLocator.instance.gemManager.addGems(item.gemsReward);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            '🎉 Claimed ${item.title}! (+${item.coinsReward} Coins, +${item.gemsReward} Gems)',
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

    for (final a in _achievements) {
      if (a.isCompleted && !a.isClaimed) {
        a.isClaimed = true;
        claimedCount++;
        try {
          await ServiceLocator.instance.rewardClaimStore.markClaimed(a.id);
        } catch (_) {}

        coinsToAdd += a.coinsReward;
        gemsToAdd += a.gemsReward;
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
              '🎉 Claimed all completed achievements! (+$coinsToAdd Coins, +$gemsToAdd Gems)',
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
    final hasUnclaimed = _achievements.any((a) => a.isCompleted && !a.isClaimed);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Dark Translucent Overlay
          Container(
            color: Colors.black.withAlpha(60),
          ),

          // 3. Content Layout
          SafeArea(
            child: Column(
              children: [
                WoodSignHeader(
                  title: 'Achievements',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 8),

                // Main Wood Sign Container
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
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
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 2.8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 10),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD54F)))
                        : Column(
                            children: [
                              // Inner Cream List Container
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFFDF5), Color(0xFFFBF1DB)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5D2A6), width: 1.5),
                                  ),
                                  child: ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: _achievements.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      color: Color(0xFFE2CCAE),
                                      thickness: 1,
                                      height: 14,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = _achievements[index];
                                      return _buildAchievementRow(item);
                                    },
                                  ),
                                ),
                              ),

                              if (hasUnclaimed) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: GlossyButton(
                                    text: 'Claim All',
                                    color: GlossyButtonColor.green,
                                    height: 44,
                                    fontSize: 16,
                                    onPressed: _claimAll,
                                  ),
                                ),
                              ],
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

  Widget _buildAchievementRow(AchievementItem item) {
    final progressFactor = item.target > 0
        ? (item.current / item.target).clamp(0.0, 1.0)
        : 0.0;
    final isReadyToClaim = item.isCompleted && !item.isClaimed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 1. Badge Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0D4),
              shape: BoxShape.circle,
              border: Border.all(
                color: isReadyToClaim ? const Color(0xFFFFD54F) : const Color(0xFFD7CCC8),
                width: isReadyToClaim ? 2.0 : 1.4,
              ),
              boxShadow: [
                if (isReadyToClaim)
                  const BoxShadow(
                    color: Color(0xFFFFD54F),
                    offset: Offset(0, 0),
                    blurRadius: 4,
                  ),
              ],
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),

          const SizedBox(width: 8),

          // 2. Title, Description, and Progress Bar
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3E200C),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7A4E24),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),

                // Progress Bar
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7CCC8),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 1.0),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progressFactor,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.isCompleted
                                  ? const [Color(0xFF81C784), Color(0xFF43A047), Color(0xFF2E7D32)]
                                  : const [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${item.current.clamp(0, item.target)}/${item.target}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
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

          // 3. Rewards Badges (Coins & Gems)
          SizedBox(
            width: 54,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/icons/icon_coin.png', width: 14, height: 14),
                      const SizedBox(width: 2),
                      Text(
                        '+${item.coinsReward}',
                        style: const TextStyle(
                          color: Color(0xFF3E200C),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/icons/icon_gem.png', width: 14, height: 14),
                      const SizedBox(width: 2),
                      Text(
                        '+${item.gemsReward}',
                        style: const TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // 4. Claim Button (Locked if incomplete, Active if completed, Claimed if done)
          SizedBox(
            width: 66,
            child: GlossyButton(
              text: item.isClaimed
                  ? 'Claimed'
                  : (item.isCompleted ? 'Claim' : 'Claim'),
              color: item.isClaimed
                  ? GlossyButtonColor.blue
                  : (item.isCompleted ? GlossyButtonColor.green : GlossyButtonColor.gold),
              height: 32,
              fontSize: 11.5,
              borderRadius: 8,
              padding: EdgeInsets.zero,
              onPressed: isReadyToClaim ? () => _claimAchievement(item) : null,
            ),
          ),
        ],
      ),
    );
  }
}
