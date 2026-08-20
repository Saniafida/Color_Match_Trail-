import 'package:flutter/material.dart';
import '../../../game/profile/avatar_definition.dart';

class AvatarSelector extends StatelessWidget {
  final List<AvatarDefinition> availableAvatars;
  final String currentAvatarId;
  final Function(String) onAvatarSelected;

  const AvatarSelector({
    Key? key,
    required this.availableAvatars,
    required this.currentAvatarId,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: availableAvatars.length,
      itemBuilder: (context, index) {
        final avatar = availableAvatars[index];
        final isSelected = avatar.avatarId == currentAvatarId;
        
        // In a real app, this logic would consult the unlock progression system
        // For now, we assume all provided in availableAvatars list are selectable.
        final bool isLocked = false; 

        return GestureDetector(
          onTap: () {
            if (!isLocked) {
              onAvatarSelected(avatar.avatarId);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected 
                  ? Border.all(color: Colors.amber, width: 3) 
                  : Border.all(color: Colors.transparent, width: 3),
              color: isLocked ? Colors.grey[800] : Colors.white24,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.person,
                  size: 48,
                  color: isLocked ? Colors.white24 : Colors.white,
                ),
                if (isLocked)
                  const Icon(Icons.lock, color: Colors.white, size: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
