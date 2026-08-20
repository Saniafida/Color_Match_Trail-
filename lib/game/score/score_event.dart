import '../../models/models.dart';
import 'score_breakdown.dart';

class ScoreEvent {
  final String eventId;
  final int pointsAdded;
  final ScoreBreakdown breakdown;
  final Position centerPosition;
  final bool isCascade;
  
  const ScoreEvent({
    required this.eventId,
    required this.pointsAdded,
    required this.breakdown,
    required this.centerPosition,
    required this.isCascade,
  });
}
