import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../game/results/level_result_manager.dart';
import '../../game/results/level_result_state.dart';
import '../../game/results/level_result.dart';
import '../../app/routes/routes.dart';

import 'widgets/result_header.dart';
import 'widgets/star_result.dart';
import 'widgets/score_result.dart';
import 'widgets/score_breakdown.dart';
import 'widgets/moves_result.dart';
import 'widgets/combo_result.dart';
import 'widgets/blast_result.dart';
import 'widgets/reward_result.dart';
import 'widgets/result_buttons.dart';
import 'widgets/campaign_complete_card.dart';

class LevelResultScreen extends StatefulWidget {
  final String levelId;

  const LevelResultScreen({super.key, required this.levelId});

  @override
  State<LevelResultScreen> createState() => _LevelResultScreenState();
}

class _LevelResultScreenState extends State<LevelResultScreen> {
  late final LevelResultManager _resultManager;

  @override
  void initState() {
    super.initState();
    _resultManager = ServiceLocator.instance.levelResultManager;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resultManager.acknowledgeResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A38),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _resultManager,
          builder: (context, child) {
            final state = _resultManager.state;
            final result = _resultManager.currentResult;

            if (state == LevelResultState.calculating || state == LevelResultState.saving) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (state == LevelResultState.saveError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Failed to save result.', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Return to Map'),
                    ),
                  ],
                ),
              );
            }

            if (result == null) {
              return const Center(child: Text('Result missing.', style: TextStyle(color: Colors.white)));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResultHeader(isWon: result.completed),
                  const SizedBox(height: 32),
                  
                  if (result.completed) ...[
                    StarResult(stars: result.stars),
                    const SizedBox(height: 24),
                  ],

                  ScoreResult(score: result.finalScore),
                  const SizedBox(height: 16),
                  
                  if (result.completed)
                    ScoreBreakdown(
                      baseScore: result.finalScore - result.bonusScore,
                      bonusScore: result.bonusScore,
                    ),

                  const SizedBox(height: 32),
                  _buildStatsGrid(result),
                  const SizedBox(height: 32),

                  if (result.completed && result.rewardId != null)
                    RewardResult(rewardId: result.rewardId!),

                  if (result.completed && _resultManager.isCampaignComplete) ...[
                    const CampaignCompleteCard(),
                    const SizedBox(height: 32),
                  ],

                  ResultButtons(
                    isWon: result.completed,
                    onRetry: () {
                      _resultManager.reset();
                      Navigator.pushReplacementNamed(context, AppRoutes.gameplay, arguments: widget.levelId);
                    },
                    onNextLevel: _resultManager.nextLevelId != null 
                        ? () {
                            final nextId = _resultManager.nextLevelId!;
                            _resultManager.reset();
                            Navigator.pushReplacementNamed(context, AppRoutes.gameplay, arguments: nextId);
                          }
                        : null,
                    onMap: () {
                      _resultManager.reset();
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.levelSelect, (route) => route.isFirst);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid(LevelResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13), // ~0.05 opacity
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          MovesResult(used: result.movesUsed, remaining: result.movesRemaining),
          ComboResult(highestCombo: result.highestCombo),
          BlastResult(largestBlast: result.largestBlast),
        ],
      ),
    );
  }
}
