import 'dart:async';
import 'package:flutter/foundation.dart';
import '../blast/blast_controller.dart';
import '../combo/combo_controller.dart';
import '../goals/goal_controller.dart';
import '../level_result/level_result_system.dart';
import '../../core/services/audio/audio_manager.dart';
import '../../core/services/service_locator.dart';
import 'feedback_config.dart';
import 'feedback_event.dart';

class FeedbackController extends ChangeNotifier {
  final BlastController blastController;
  final ComboController comboController;
  final GoalController goalController;
  final LevelResultController levelResultController;
  final AudioManager audioManager;

  final StreamController<FeedbackEvent> _eventController = StreamController<FeedbackEvent>.broadcast();
  Stream<FeedbackEvent> get onEvent => _eventController.stream;

  StreamSubscription? _blastSubscription;
  StreamSubscription? _levelResultSubscription;
  StreamSubscription? _goalCompletedSubscription;

  int _lastComboLevel = 0;

  FeedbackController({
    required this.blastController,
    required this.comboController,
    required this.goalController,
    required this.levelResultController,
    required this.audioManager,
  }) {
    _init();
  }

  void _init() {
    _blastSubscription = blastController.onBlast.listen((result) {
      if (!result.success) return;

      // Haptic and Sound based on blast size
      if (result.destroyedCount >= FeedbackConfig.minBigMatch) {
        audioManager.playHapticMedium();
        audioManager.playBlast(isLarge: true);
        
        final settings = ServiceLocator.instance.settingsManager.state;
        if (settings.effectsEnabled && !settings.reducedEffects) {
          final text = FeedbackConfig.getMatchText(result.destroyedCount);
          if (text.isNotEmpty && result.destroyedPositions.isNotEmpty) {
            final pos = result.destroyedPositions.first;
            _eventController.add(FloatingTextFeedbackEvent(
              text: text,
              boardPosition: pos,
            ));
          }
        }
      } else {
        audioManager.playHapticLight();
        audioManager.playBlast();
      }
    });

    _levelResultSubscription = levelResultController.onLevelResult.listen((event) {
      if (event.result.status == GameStatus.won) {
        audioManager.playHapticHeavy();
        audioManager.playLevelComplete();
        _eventController.add(LevelWinFeedbackEvent());
      } else {
        audioManager.playLevelFail();
      }
    });

    _goalCompletedSubscription = goalController.onCompleted.listen((event) {
      audioManager.playHapticMedium();
      audioManager.playUI('goal_complete');
      _eventController.add(GoalCompleteFeedbackEvent(event.goalId));
    });

    comboController.addListener(_onComboChanged);
  }

  void _onComboChanged() {
    final currentLevel = comboController.state.level;
    if (currentLevel > _lastComboLevel && currentLevel > 1) {
      // Combo increased
      audioManager.playHapticMedium();
      audioManager.playCombo(currentLevel);
      
      final settings = ServiceLocator.instance.settingsManager.state;
      if (settings.effectsEnabled) {
        _eventController.add(CascadeFeedbackEvent(currentLevel));
      }
    }
    _lastComboLevel = currentLevel;
  }

  @override
  void dispose() {
    comboController.removeListener(_onComboChanged);
    _blastSubscription?.cancel();
    _levelResultSubscription?.cancel();
    _goalCompletedSubscription?.cancel();
    _eventController.close();
    super.dispose();
  }
}
