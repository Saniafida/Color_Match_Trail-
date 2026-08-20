import 'board.dart';
import 'trail.dart';
import 'combo.dart';
import 'goal.dart';

import '../game/level_result/game_status.dart';
class GameSession {
  final String levelId;
  final int movesRemaining;
  final int score;
  final Trail? currentTrail;
  final Combo combo;
  final GameStatus status;
  final List<GoalDefinition> goals;
  final Board board;

  const GameSession({
    required this.levelId,
    required this.movesRemaining,
    this.score = 0,
    this.currentTrail,
    this.combo = const Combo(),
    this.status = GameStatus.initializing,
    this.goals = const [],
    required this.board,
  }) : assert(movesRemaining >= 0, 'movesRemaining cannot be negative');

  GameSession copyWith({
    String? levelId,
    int? movesRemaining,
    int? score,
    Trail? currentTrail,
    Combo? combo,
    GameStatus? status,
    List<GoalDefinition>? goals,
    Board? board,
    bool clearTrail = false,
  }) {
    return GameSession(
      levelId: levelId ?? this.levelId,
      movesRemaining: movesRemaining ?? this.movesRemaining,
      score: score ?? this.score,
      currentTrail: clearTrail ? null : (currentTrail ?? this.currentTrail),
      combo: combo ?? this.combo,
      status: status ?? this.status,
      goals: goals ?? this.goals,
      board: board ?? this.board,
    );
  }
}
