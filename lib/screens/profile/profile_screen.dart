import 'package:flutter/material.dart';
import '../../game/profile/player_profile_manager.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_stats_card.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final PlayerProfileManager manager;

  const ProfileScreen({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          final profile = manager.profile;
          final avatar = manager.availableAvatars.firstWhere(
            (a) => a.avatarId == profile.avatarId,
            orElse: () => manager.availableAvatars.first,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(
                  profile: profile,
                  avatar: avatar,
                  onEditPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(manager: manager),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ProfileStatsCard(stats: profile.statistics),
                      // Additional cards (Achievements) 
                      // could be placed here in future expansions.
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
