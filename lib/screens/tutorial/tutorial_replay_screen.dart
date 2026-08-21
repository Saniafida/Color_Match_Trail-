import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';


class TutorialReplayScreen extends StatelessWidget {
  const TutorialReplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tutorialManager = ServiceLocator.instance.tutorialManager;

    return Scaffold(
      backgroundColor: const Color(0xFF1E2A38),
      appBar: AppBar(
        title: const Text('Replay Tutorials'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReplayCard(
            context,
            'Main Mechanics',
            'Learn how to match blocks, create blasts, and use moves.',
            () {
              tutorialManager.replayTutorial('main_mechanics');
              Navigator.pushNamed(context, '/gameplay', arguments: '1');
            },
          ),
          const SizedBox(height: 16),
          _buildReplayCard(
            context,
            'Boosters',
            'Learn how to use boosters to clear obstacles.',
            () {
              tutorialManager.replayTutorial('boosters_intro');
              Navigator.pushNamed(context, '/gameplay', arguments: '3');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReplayCard(BuildContext context, String title, String description, VoidCallback onPlay) {
    return Card(
      color: const Color(0xFF34495E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            description,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onPlay,
          child: const Text('Play', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
