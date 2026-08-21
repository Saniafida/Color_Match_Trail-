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
import '../../game/achievements/achievement_event.dart';
import '../../core/services/timer/timer.dart';
import '../../game/goals/goal_controller.dart';
import '../../app/routes/routes.dart';
import '../../game/feedback/feedback_controller.dart';

// New UI widgets
import 'widgets/gameplay_hud.dart';
import 'widgets/goal_panel.dart';
import 'widgets/combo_display.dart';
import 'widgets/booster_bar.dart';
import '../tutorial/tutorial_overlay.dart';
import '../../game/tutorial/tutorial_validator.dart';
import 'widgets/pause_dialog.dart';
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
  int _highestCombo = 0;
  int _largestBlast = 0;

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
      minimumConnectionLength: 2, // Changed to 2
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ServiceLocator.instance.tutorialManager.checkAndStartTutorial(widget.levelId);
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
      if (_level.timeLimit != null) {
        _timerController.stop();
      }

      ServiceLocator.instance.levelResultManager.processResult(
        event: event,
        levelData: _level,
        highestCombo: _highestCombo,
        largestBlast: _largestBlast,
      );

      // Navigate to LevelResultScreen
      Navigator.pushReplacementNamed(context, AppRoutes.levelResult, arguments: widget.levelId);
    }
  }

  Future<void> _onTrailCompleted(Trail trail) async {
    const minMatch = 2; // Changed to 2
    if (trail.positions.length < minMatch) {
      return;
    }
    
    final tutorialManager = ServiceLocator.instance.tutorialManager;
    if (tutorialManager.isActive) {
      final step = tutorialManager.currentStep;
      if (step != null && step.requiredAction == 'connect') {
        tutorialManager.advanceStep();
      }
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
    if (blastResult.destroyedPositions.length > _largestBlast) {
      setState(() => _largestBlast = blastResult.destroyedPositions.length);
    }
    
    // Dispatch Achievement Event
    final isMega = blastResult.specialCreationHint != SpecialCreationType.none;
    final blastEvent = BlockBlastEvent(blastResult.destroyedPositions.length, isMegaBlast: isMega);
    ServiceLocator.instance.achievementManager.processEvent(blastEvent);
    ServiceLocator.instance.milestoneManager.processEvent(blastEvent);

    _goalController.onBlastResult(blastResult);
    await _scoreController.processBlast(blastResult);
    if (_scoreController.lastScoreEvent != null) {
      _goalController.onScoreEvent(_scoreController.lastScoreEvent!);
    }
    
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
      
      SpecialBlockType specType = SpecialBlockType.none;
      switch (blastResult.specialCreationHint) {
        case SpecialCreationType.lineBlast:
          specType = SpecialBlockType.horizontalLine;
          break;
        case SpecialCreationType.bomb:
          specType = SpecialBlockType.bomb;
          break;
        case SpecialCreationType.colorBomb:
        case SpecialCreationType.megaSpecial:
          specType = SpecialBlockType.colorSpecial;
          break;
        default:
          specType = SpecialBlockType.none;
      }
      _goalController.onSpecialCreation(SpecialCreationResult(
        created: true,
        type: specType,
      ));
    }
    
    // Trigger cascades
    final allowedColors = _level.colorConfig?.availableColors ?? [];
    final cascadeResult = await _cascadeController.startCascade(allowedColors);
    if (cascadeResult.cascadeLevel > 0) {
      _goalController.onCascadeResult(cascadeResult);
      dailyManager.incrementProgress(DailyChallengeType.cascade, cascadeResult.cascadeLevel);
      dailyManager.updateProgressMax(DailyChallengeType.combo, _comboController.state.level);
      
      eventManager.incrementProgress(EventType.cascade, cascadeResult.cascadeLevel);
      eventManager.updateProgressMax(EventType.combo, _comboController.state.level);
    }

    if (_comboController.state.level > _highestCombo) {
      setState(() => _highestCombo = _comboController.state.level);
    }
    
    // Dispatch Combo Event
    final comboEvent = ComboEvent(_comboController.state.level);
    ServiceLocator.instance.achievementManager.processEvent(comboEvent);
    ServiceLocator.instance.milestoneManager.processEvent(comboEvent);
    
    _levelResultController.setResolving(false);
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
        child: TutorialOverlay(
          tutorialManager: ServiceLocator.instance.tutorialManager,
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
                              cellSize: (MediaQuery.of(context).size.width - 48) / _level.boardConfig.columns,
                              cellSpacing: 2.0,
                              onDragStart: (pos) {
                                if (!TutorialValidator.canStartDrag(ServiceLocator.instance.tutorialManager, pos, _boardController)) return;
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
      ),
    );
  }
}
