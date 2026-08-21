import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/world_definition.dart';
import '../../../game/progression/world_progress.dart';

class WorldNavigation extends StatelessWidget {
  final List<WorldDefinition> worlds;
  final int selectedIndex;
  final Function(int) onWorldSelected;
  final WorldProgress Function(String worldId) getWorldProgress;

  const WorldNavigation({
    super.key,
    required this.worlds,
    required this.selectedIndex,
    required this.onWorldSelected,
    required this.getWorldProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (worlds.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: worlds.length,
        itemBuilder: (context, index) {
          final world = worlds[index];
          final progress = getWorldProgress(world.worldId);
          final isSelected = index == selectedIndex;
          final isUnlocked = progress.unlocked;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onWorldSelected(index);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : (isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF0F172A)),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : (isUnlocked ? Colors.white24 : Colors.white10),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUnlocked) ...[
                      const Icon(Icons.lock_rounded, size: 14, color: Colors.white54),
                      const SizedBox(width: 6),
                    ] else if (progress.isCompleted) ...[
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      world.titleKey,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF0F172A)
                            : (isUnlocked ? Colors.white : Colors.white54),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
