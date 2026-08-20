import 'package:flutter/material.dart';
import '../../game/rewards/reward_definition.dart';
import 'reward_item.dart';

class RewardPopup {
  static void show(BuildContext context, List<RewardDefinition> rewards) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _RewardPopupDialog(rewards: rewards);
      },
    );
  }
}

class _RewardPopupDialog extends StatefulWidget {
  final List<RewardDefinition> rewards;

  const _RewardPopupDialog({required this.rewards});

  @override
  State<_RewardPopupDialog> createState() => _RewardPopupDialogState();
}

class _RewardPopupDialogState extends State<_RewardPopupDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A38),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withAlpha(76),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "REWARD!",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: widget.rewards.map((r) => RewardItemWidget(reward: r)).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "CONTINUE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
