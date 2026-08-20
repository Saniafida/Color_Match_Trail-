import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../game/achievements/achievement_category.dart';
import 'widgets/achievement_card.dart';
import 'widgets/achievement_category_tabs.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _manager = ServiceLocator.instance.achievementManager;
  AchievementCategory _selectedCategory = AchievementCategory.all;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onAchievementsChanged);
  }

  @override
  void dispose() {
    _manager.removeListener(_onAchievementsChanged);
    super.dispose();
  }

  void _onAchievementsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var defs = _manager.definitions;
    if (_selectedCategory != AchievementCategory.all) {
      defs = defs.where((d) => d.category == _selectedCategory).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141E2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ACHIEVEMENTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
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
                final prog = _manager.progress[def.id]!;
                return AchievementCard(definition: def, progress: prog);
              },
            ),
          ),
        ],
      ),
    );
  }
}
