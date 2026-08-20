import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../models/models.dart';
import '../../game/board/board.dart';
import '../../game/trail/trail_controller.dart';
import '../../game/board/board_widget.dart';
import '../../game/trail/match_result.dart';
import '../../game/levels/initial_board_generator.dart';
import '../../game/cascade/cascade.dart';
import '../../game/gravity/gravity.dart';
import '../../game/specials/special.dart';
import '../../game/blast/blast.dart';
import '../../game/score/score_controller.dart';
import '../../game/combo/combo_controller.dart';
import '../../game/level_result/level_result_system.dart';
import '../../game/moves/moves.dart';
import '../../core/services/timer/timer.dart';
import '../../game/goals/goal_controller.dart';
import '../../app/routes/routes.dart';
import '../../game/feedback/feedback_controller.dart';

// New UI widgets
import 'widgets/gameplay_hud.dart';
import 'widgets/goal_panel.dart';
import 'widgets/combo_display.dart';
import 'widgets/booster_bar.dart';
import 'widgets/pause_dialog.dart';
import 'widgets/win_overlay.dart';
import 'widgets/lose_overlay.dart';
import 'widgets/feedback/feedback_layer.dart';

import '../../game/boosters/booster_manager.dart';
import '../../game/boosters/booster_target_controller.dart';
import 'widgets/booster_target_overlay.dart';
import '../../game/challenges/daily_challenge_type.dart';
import '../../game/events/event_type.dart';

class GameplayScreen extends StatefulWidget {
  final String levelId;
  const GameplayScreen({super.key, required this.levelId});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late LevelDefinition _level;
  
  // Game State
  final Map<String, Block> _blocks = {};
  
  // Logical Controllers
  late BoardController _boardController;
  late ComboController _comboController;
  late ScoreController _scoreController;
  late GoalController _goalController;
  late MoveController _moveController;
  late TimerController _timerController;
  late LevelResultController _levelResultController;
  
  late GravityController _gravityController;
  late SpecialController _specialController;
  late BlastController _blastController;
  late BoardMatchScanner _matchScanner;
  late CascadeController _cascadeController;
  late TrailController _trailController;
  late BoosterManager _boosterManager;
  late BoosterTargetController _boosterTargetController;
  late FeedbackController _feedbackController;

  bool _isInitialized = false;
  int _starsEarned = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final parsedId = int.tryParse(widget.levelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    _level = await ServiceLocator.instance.levelRepository.getLevel(parsedId);
    
    // 1. Initialize State Controllers
    _comboController = ComboController();
    _scoreController = ScoreController(
      comboController: _comboController, 
    );
    _goalController = GoalController();
    _moveController = MoveController();
    _timerController = TimerController();
    
    // Initialize their limits
    _moveController.initialize(_level.movesLimit);
    _timerController.initialize(_level.timeLimit);
    _goalController.initialize(_level.goals);

    _levelResultController = LevelResultController(
      winCondition: WinConditionController(
        goalController: _goalController,
        winRule: _level.winRule,
      ),
      loseCondition: LoseConditionController(
        moveController: _moveController,
        timerController: _timerController,
        loseRule: _level.loseRule,
      ),
      moveController: _moveController,
      timerController: _timerController,
      goalController: _goalController,
      scoreController: _scoreController,
      levelDefinition: _level,
    );
    _levelResultController.onLevelResult.listen(_onLevelResult);

    // 2. Initialize Board Controllers
    _boardController = BoardController(
      rows: _level.boardConfig.rows,
      columns: _level.boardConfig.columns,
    );

    _gravityController = GravityController(
      boardController: _boardController,
      getBlock: (id) => _blocks[id],
      onUpdateBlock: (b) => setState(() => _blocks[b.id] = b),
      onCreateBlock: (b) => setState(() => _blocks[b.id] = b),
    );

    _specialController = SpecialController(
      boardController: _boardController,
      getBlock: (id) => _blocks[id],
    );

    _blastController = BlastController(
      boardController: _boardController,
      getBlock: (id) => _blocks[id],
      onUpdateBlock: (b) => setState(() => _blocks[b.id] = b),
      onRemoveBlock: (id) => setState(() => _blocks.remove(id)),
      specialController: _specialController,
    );
    
    _matchScanner = BoardMatchScanner(
      boardController: _boardController,
      getBlock: (id) => _blocks[id],
      minimumConnectionLength: 3,
    );

    _cascadeController = CascadeController(
      matchScanner: _matchScanner,
      blastController: _blastController,
      gravityController: _gravityController,
    );

    _trailController = TrailController(
      boardController: _boardController,
      getBlock: (id) => _blocks[id],
      onUpdateBlock: (b) => setState(() => _blocks[b.id] = b),
      onTrailCompleted: _onTrailCompleted,
    );

    _boosterManager = BoosterManager(
      boardController: _boardController,
      blastController: _blastController,
      moveController: _moveController,
      levelResultController: _levelResultController,
      storage: ServiceLocator.instance.storage,
      getBlock: (id) => _blocks[id],
      onMoveBlock: (id, pos) {
        // Not heavily used for basic boosters
      },
      specialController: _specialController,
    );

    _boosterManager.loadInventory();

    _boosterTargetController = BoosterTargetController(
      boosterManager: _boosterManager,
      isValidTarget: (pos) => _boardController.isValidPosition(pos) && _boardController.getBlockId(pos) != null,
    );

    _feedbackController = FeedbackController(
      blastController: _blastController,
      comboController: _comboController,
      goalController: _goalController,
      levelResultController: _levelResultController,
      audioManager: ServiceLocator.instance.audioManager,
    );

    // 3. Generate initial board
    final generator = InitialBoardGenerator();
    final initialBoard = generator.generate(_level);
    _boardController.loadState(initialBoard);
    _blocks.clear();
    _blocks.addAll(initialBoard.blocks);

    final bestScore = ServiceLocator.instance.progressionManager.state.levels[widget.levelId]?.bestScore ?? 0;
    _scoreController.init(bestScore);
    _levelResultController.startGame();
    
    if (_level.timeLimit != null) {
      _timerController.start();
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _trailController.dispose();
    _cascadeController.dispose();
    _blastController.dispose();
    _levelResultController.dispose();
    _scoreController.dispose();
    _comboController.dispose();
    _goalController.dispose();
    _moveController.dispose();
    _timerController.dispose();
    _specialController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _onLevelResult(LevelResultEvent event) async {
    if (event.result.status == GameStatus.won || event.result.status == GameStatus.lost) {
      final isWon = event.result.status == GameStatus.won;
      
      if (_level.timeLimit != null) {
        _timerController.stop();
      }

      // Save progress if won
      if (isWon) {
        // Simple star calculation based on completion
        final calculatedStars = 3; 

        ServiceLocator.instance.progressionManager.saveLevelResult(
          levelId: widget.levelId,
          score: event.result.finalScore,
          stars: calculatedStars,
          movesUsed: (_level.movesLimit ?? 0) - event.result.remainingMoves,
          highestCombo: 0, // Fallback, would need tracking from ComboController
          completed: true,
        );
        
        // Notify Daily Challenge System
        ServiceLocator.instance.dailyChallengeManager.incrementProgress(DailyChallengeType.completeLevel, 1);
        
        // Notify Event System
        ServiceLocator.instance.eventManager.incrementProgress(EventType.levelCampaign, 1);
        
        // Fetch earned stars for UI
        _starsEarned = calculatedStars;
      }
      
      _showGameEndOverlay(isWon, event.result.finalScore);
    }
  }

  Future<void> _onTrailCompleted(Trail trail) async {
    const minMatch = 3;
    if (trail.positions.length < minMatch) {
      return;
    }
    
    _levelResultController.setResolving(true);
    _moveController.consumeMove();

    // The Trail is basically a MatchResult
    final matchResult = MatchResult(
      isValid: true,
      length: trail.positions.length,
      positions: trail.positions,
      blockIds: trail.blockIds,
      color: trail.color!,
      connectionType: ConnectionType.normal,
    );

    // Blast the trail blocks
    final blastResult = await _blastController.processMatch(matchResult);
    _goalController.onBlastResult(blastResult);
    _scoreController.processBlast(blastResult);
    
    final dailyManager = ServiceLocator.instance.dailyChallengeManager;
    final eventManager = ServiceLocator.instance.eventManager;
    
    dailyManager.incrementProgress(DailyChallengeType.clearBlocks, blastResult.destroyedPositions.length);
    dailyManager.incrementProgress(DailyChallengeType.score, _scoreController.lastScoreEvent?.pointsAdded ?? 0);
    dailyManager.updateProgressMax(DailyChallengeType.combo, _comboController.state.level);

    eventManager.incrementProgress(EventType.clearBlocks, blastResult.destroyedPositions.length);
    eventManager.incrementProgress(EventType.score, _scoreController.lastScoreEvent?.pointsAdded ?? 0);
    eventManager.updateProgressMax(EventType.combo, _comboController.state.level);

    if (blastResult.specialCreationHint != SpecialCreationType.none) {
      dailyManager.incrementProgress(DailyChallengeType.createSpecial, 1);
      eventManager.incrementProgress(EventType.createSpecial, 1);
    }
    
    // Trigger cascades
    final allowedColors = _level.colorConfig?.availableColors ?? [];
    final cascadeResult = await _cascadeController.startCascade(allowedColors);
    if (cascadeResult.cascadeLevel > 0) {
      dailyManager.incrementProgress(DailyChallengeType.cascade, cascadeResult.cascadeLevel);
      dailyManager.updateProgressMax(DailyChallengeType.combo, _comboController.state.level);
      
      eventManager.incrementProgress(EventType.cascade, cascadeResult.cascadeLevel);
      eventManager.updateProgressMax(EventType.combo, _comboController.state.level);
    }
    
    _levelResultController.setResolving(false);
  }

  void _showGameEndOverlay(bool won, int finalScore) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        if (won) {
          return WinOverlay(
            score: finalScore,
            stars: _starsEarned,
            onContinue: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit to Map
            },
            onReplay: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, AppRoutes.gameplay, arguments: widget.levelId);
            },
          );
        } else {
          return LoseOverlay(
            onRetry: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, AppRoutes.gameplay, arguments: widget.levelId);
            },
            onExit: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit to Map
            },
          );
        }
      },
    );
  }

  void _onPause() {
    if (_level.timeLimit != null) _timerController.stop();
    _levelResultController.setResolving(true); // Lock input
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PauseDialog(
        onResume: () {
          Navigator.pop(context);
          if (_level.timeLimit != null) _timerController.start();
          _levelResultController.setResolving(false);
        },
        onRestart: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, AppRoutes.gameplay, arguments: widget.levelId);
        },
        onExit: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Exit to Map
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF2C3E50),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final renderBoard = _boardController.board.copyWith(blocks: _blocks);

    return Scaffold(
      backgroundColor: const Color(0xFF1E2A38),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top HUD — wrapped in RepaintBoundary so board repaints
            //    don't cascade upward into HUD widgets
            RepaintBoundary(
              child: GameplayHud(
                levelId: widget.levelId,
                onPause: _onPause,
                scoreController: _scoreController,
                moveController: _moveController,
                timerController: _timerController,
                hasTimeLimit: _level.timeLimit != null,
              ),
            ),
            
            // 2. Goal Panel
            RepaintBoundary(
              child: GoalPanel(goalController: _goalController),
            ),
            
            const SizedBox(height: 16),
            
            // 3. Game Board + Combo Overlay
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _levelResultController,
                      _cascadeController,
                      _trailController,
                      _gravityController,
                    ]),
                    builder: (context, child) {
                      final isLocked = _levelResultController.status != GameStatus.playing ||
                                       _cascadeController.inputLocked;
                      return AbsorbPointer(
                        absorbing: isLocked,
                        child: Center(
                          child: BoardWidget(
                            board: renderBoard,
                            trail: _trailController.activeTrail,
                            cellSize: MediaQuery.of(context).size.width / (_level.boardConfig.columns + 1.5),
                            cellSpacing: 4.0,
                            onDragStart: (pos) {
                              if (_boosterTargetController.isTargeting) {
                                _boosterTargetController.handleTap(pos);
                              } else {
                                _trailController.handleDragStart(pos);
                              }
                            },
                            onDragUpdate: (pos) {
                              if (!_boosterTargetController.isTargeting) {
                                _trailController.handleDragUpdate(pos);
                              }
                            },
                            onDragEnd: () => _trailController.handleDragEnd(),
                            onDragCancel: () => _trailController.handleDragCancel(),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Overlay for Feedback effects (particles, text)
                  Positioned.fill(
                    child: FeedbackLayer(feedbackController: _feedbackController),
                  ),

                  // Overlay for Target Selection mode
                  Positioned.fill(
                    child: BoosterTargetOverlay(targetController: _boosterTargetController),
                  ),

                  // Combo Display overlay
                  Positioned(
                    top: 20,
                    child: ComboDisplay(comboController: _comboController),
                  ),
                ],
              ),
            ),
            
            // 4. Booster Bar
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: BoosterBar(boosterManager: _boosterManager),
            ),
          ],
        ),
      ),
    );
  }
}
