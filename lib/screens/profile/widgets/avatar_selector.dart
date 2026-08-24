import 'package:flutter/material.dart';
import '../../../game/profile/avatar_definition.dart';

class AvatarSelector extends StatelessWidget {
  final List<AvatarDefinition> availableAvatars;
  final String currentAvatarId;
  final Function(String) onAvatarSelected;

  const AvatarSelector({
    super.key,
    required this.availableAvatars,
    required this.currentAvatarId,
    required this.onAvatarSelected,
  });

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

        return GestureDetector(
          onTap: () => onAvatarSelected(avatar.avatarId),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected 
                  ? Border.all(color: Colors.amber, width: 3) 
                  : Border.all(color: Colors.transparent, width: 3),
              color: Colors.white24,
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
