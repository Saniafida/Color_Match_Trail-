import 'package:flutter/material.dart';
import '../../../game/achievements/achievement_category.dart';

class AchievementCategoryTabs extends StatelessWidget {
  final AchievementCategory selectedCategory;
  final ValueChanged<AchievementCategory> onSelect;

  const AchievementCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AchievementCategory.values.length,
        itemBuilder: (context, index) {
          final cat = AchievementCategory.values[index];
          final isSelected = cat == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelect(cat),
              selectedColor: Colors.amber,
              backgroundColor: const Color(0xFF1B2735),
            ),
          );
        },
      ),
    );
  }
}
