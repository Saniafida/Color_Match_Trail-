import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../game/achievements/achievement_category.dart';
import 'widgets/achievement_card.dart';
import 'widgets/milestone_card.dart';
import 'widgets/achievement_category_tabs.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _achManager = ServiceLocator.instance.achievementManager;
  final _mileManager = ServiceLocator.instance.milestoneManager;
  AchievementCategory _selectedCategory = AchievementCategory.all;

  @override
  void initState() {
    super.initState();
    _achManager.addListener(_onDataChanged);
    _mileManager.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _achManager.removeListener(_onDataChanged);
    _mileManager.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF141E2A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'PROGRESS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: 'ACHIEVEMENTS'),
              Tab(text: 'MILESTONES'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAchievementsTab(),
            _buildMilestonesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    var defs = _achManager.definitions;
    if (_selectedCategory != AchievementCategory.all) {
      defs = defs.where((d) => d.category == _selectedCategory).toList();
    }

    return Column(
      children: [
        AchievementCategoryTabs(
          selectedCategory: _selectedCategory,
          onSelect: (c) => setState(() => _selectedCategory = c),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: defs.length,
            itemBuilder: (context, index) {
              final def = defs[index];
              final prog = _achManager.progress[def.achievementId]!;
              return AchievementCard(definition: def, progress: prog);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesTab() {
    final defs = _mileManager.definitions;
    return ListView.builder(
      itemCount: defs.length,
      itemBuilder: (context, index) {
        final def = defs[index];
        final prog = _mileManager.progress[def.milestoneId]!;
        return MilestoneCard(definition: def, progress: prog);
      },
    );
  }
}
