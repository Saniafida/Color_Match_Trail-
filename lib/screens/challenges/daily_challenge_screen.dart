import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
import 'widgets/daily_challenge_card.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final _manager = ServiceLocator.instance.dailyChallengeManager;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _manager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _manager.currentChallenge;
    final progress = _manager.currentProgress;

    return Scaffold(
      backgroundColor: const Color(0xFF1E2A38),
      appBar: AppBar(
        title: const Text("Daily Challenge"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (challenge != null && progress != null)
                DailyChallengeCard(
                  challenge: challenge,
                  progress: progress,
                  onClaim: () {
                    _manager.claimReward();
                  },
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
