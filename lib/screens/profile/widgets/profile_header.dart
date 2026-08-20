import 'package:flutter/material.dart';
import '../../../game/profile/player_profile.dart';
import '../../../game/profile/avatar_definition.dart';

class ProfileHeader extends StatelessWidget {
  final PlayerProfile profile;
  final AvatarDefinition avatar;
  final VoidCallback onEditPressed;

  const ProfileHeader({
    Key? key,
    required this.profile,
    required this.avatar,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 48, bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[800]!, Colors.indigo[900]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: onEditPressed,
              ),
            ],
          ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white24,
                // In a real app this would load the actual assetPath from the avatar definition
                child: Icon(Icons.person, size: 64, color: Colors.white.withValues(alpha: 0.8)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.indigo[900]!, width: 3),
                ),
                padding: const EdgeInsets.all(6),
                child: Text(
                  '${profile.playerLevel}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${profile.playerId.substring(0, 8)}...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
