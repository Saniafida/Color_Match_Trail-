import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../combo/combo_controller.dart';
import '../blast/blast_result.dart';
import 'score_state.dart';
import 'score_event.dart';
import 'score_calculator.dart';

class ScoreController extends ChangeNotifier {
  final ComboController comboController;

  ScoreState _state = const ScoreState();
  ScoreState get state => _state;

  ScoreEvent? _lastScoreEvent;
  ScoreEvent? get lastScoreEvent => _lastScoreEvent;
  
  final Set<String> _processedEventIds = {};

  ScoreController({
    required this.comboController,
  });

  void init(int bestScore) {
    _state = _state.copyWith(highScore: bestScore);
    notifyListeners();
  }

  Future<void> processBlast(BlastResult blastResult, {int cascadeLevel = 0}) async {
    if (!blastResult.success || blastResult.destroyedPositions.isEmpty) return;

    // Provide a unique event ID for the score deduplication
    // Using blastResult's destroyed block count + position sum to create a stable hash in case
    // the identical result is piped twice.
    int posHash = 0;
    for (final p in blastResult.destroyedPositions) {
      posHash += (p.row * 100 + p.column).toInt();
    }
    
    final eventId = 'blast_${blastResult.destroyedCount}_$posHash';
    if (_processedEventIds.contains(eventId)) return;
    _processedEventIds.add(eventId);

    if (cascadeLevel > 0) {
      comboController.registerCascade(cascadeLevel);
    } else {
      comboController.registerScoreEvent();
    }

    final comboLevel = comboController.state.level;
    final destroyedCount = blastResult.destroyedCount;

    final breakdown = ScoreCalculator.calculate(
      destroyedBlocks: destroyedCount,
      cascadeLevel: cascadeLevel,
      comboLevel: comboLevel,
    );

    int newScore = _state.currentScore + breakdown.finalScore;
    int newHighScore = _state.highScore;
    
    if (newScore > newHighScore) {
      newHighScore = newScore;
    }

    _state = _state.copyWith(
      currentScore: newScore,
      highScore: newHighScore,
      lastAddedScore: breakdown.finalScore,
      comboLevel: comboLevel,
      cascadeLevel: cascadeLevel,
    );

    // Calculate center position for popup
    double sumR = 0, sumC = 0;
    for (final pos in blastResult.destroyedPositions) {
      sumR += pos.row;
      sumC += pos.column;
    }
    final center = Position(
      (sumR / destroyedCount).round(),
      (sumC / destroyedCount).round()
    );

    _lastScoreEvent = ScoreEvent(
      eventId: eventId,
      pointsAdded: breakdown.finalScore,
      breakdown: breakdown,
      centerPosition: center,
      isCascade: cascadeLevel > 0,
    );

    notifyListeners();
  }

  Future<void> resetScore() async {
    _state = _state.copyWith(
      currentScore: 0,
      lastAddedScore: 0,
      comboLevel: 0,
      cascadeLevel: 0,
    );
    comboController.reset();
    _processedEventIds.clear();
    notifyListeners();
  }
}
