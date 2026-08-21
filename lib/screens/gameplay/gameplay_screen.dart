import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../game/board/board.dart';
import '../../game/board/board_widget.dart';
import '../../game/combos/combo_controller.dart';
import '../../game/score/score_controller.dart';
import '../../game/goals/goal_controller.dart';
import '../../game/moves/move_controller.dart';
import '../../game/timer/timer_controller.dart';
import '../../game/level_result/level_result_system.dart';
import '../../game/levels/initial_board_generator.dart';
import '../../game/gravity/gravity_controller.dart';
import '../../game/specials/special_controller.dart';
import '../../game/specials/power_up_manager.dart';
import '../../game/blast/blast_controller.dart';
import '../../game/blast/blast_result.dart';
import '../../game/cascade/board_match_scanner.dart';
import '../../game/cascade/cascade_controller.dart';
import '../../game/trail/trail_controller.dart';
import '../../game/trail/match_result.dart';
import '../../game/boosters/booster_manager.dart';
import '../../game/boosters/booster_target_controller.dart';
import '../../game/feedback/feedback_controller.dart';
import '../../game/tutorial/tutorial_validator.dart';
import '../../game/achievements/achievement_event.dart';
import '../../game/challenges/daily_challenge_type.dart';
import '../../game/events/event_type.dart';
import '../../core/services/service_locator.dart';
import '../../app/routes/routes.dart';

import 'widgets/gameplay_hud.dart';
import 'widgets/goal_panel.dart';
import 'widgets/booster_bar.dart';
import 'widgets/booster_target_overlay.dart';
import 'widgets/combo_display.dart';
import 'widgets/feedback/feedback_layer.dart';
import 'widgets/pause_dialog.dart';
import '../tutorial/widgets/tutorial_overlay.dart';

class GameplayScreen extends StatefulWidget {
  final String levelId;

  const GameplayScreen({
    super.key,
    required this.levelId,
  });

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
  late PowerUpManager _powerUpManager;
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

    _powerUpManager = PowerUpManager(
      boardController: _boardController,
      getBlock: (id) => _blocks[id],
      onUpdateBlock: (b) => setState(() => _blocks[b.id] = b),
      onRemoveBlock: (id) => setState(() => _blocks.remove(id)),
      specialController: _specialController,
      blastController: _blastController,
    );
    
    _matchScanner = BoardMatchScanner(
      boardController: _boardController,
      getBlock: (id) => _blocks[id],
      minimumConnectionLength: 2,
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
      onMoveBlock: (id, pos) {},
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
    _powerUpManager.dispose();
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

      Navigator.pushReplacementNamed(context, AppRoutes.levelResult, arguments: widget.levelId);
    }
  }

  Future<void> _onTrailCompleted(Trail trail) async {
    // 1. Check Single-Tap on Power-Up Block
    if (trail.positions.length == 1) {
      final pos = trail.positions.first;
      final blockId = _boardController.getBlockId(pos);
      if (blockId != null) {
        final block = _blocks[blockId];
        if (block != null && block.isPowerUp) {
          await _handlePowerUpTapActivation(pos);
          return;
        }
      }
      return;
    }

    const minMatch = 2;
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

    final count = trail.positions.length;
    final isPowerUpCreation = count >= 4;

    if (isPowerUpCreation) {
      // 2. Power-Up Transformation Flow (Block transforms, others disappear into it)
      final transformResult = await _powerUpManager.processTrailPowerUp(
        blockIds: trail.blockIds,
        positions: trail.positions,
        color: trail.color!,
      );

      final blastResult = BlastResult(
        success: true,
        destroyedBlockIds: transformResult.removedBlockIds,
        destroyedPositions: transformResult.removedPositions,
        destroyedCount: transformResult.removedPositions.length,
        color: trail.color,
        intensity: BlastIntensity.normal,
        duration: Duration.zero,
        source: DestructionSource.playerMatch,
      );

      if (blastResult.destroyedPositions.length > _largestBlast) {
        setState(() => _largestBlast = blastResult.destroyedPositions.length);
      }

      final blastEvent = BlockBlastEvent(blastResult.destroyedPositions.length, isMegaBlast: count >= 7);
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
      dailyManager.incrementProgress(DailyChallengeType.createSpecial, 1);
      eventManager.incrementProgress(EventType.clearBlocks, blastResult.destroyedPositions.length);
      eventManager.incrementProgress(EventType.createSpecial, 1);

      _goalController.onSpecialCreation(SpecialCreationResult(
        created: true,
        type: transformResult.specialType,
      ));
    } else {
      // 3. Normal Blast (Length 2-3, no power-up)
      final matchResult = MatchResult(
        isValid: true,
        length: trail.positions.length,
        positions: trail.positions,
        blockIds: trail.blockIds,
        color: trail.color!,
        connectionType: ConnectionType.normal,
      );

      final blastResult = await _blastController.processMatch(matchResult);
      if (blastResult.destroyedPositions.length > _largestBlast) {
        setState(() => _largestBlast = blastResult.destroyedPositions.length);
      }

      final blastEvent = BlockBlastEvent(blastResult.destroyedPositions.length, isMegaBlast: false);
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
      eventManager.incrementProgress(EventType.clearBlocks, blastResult.destroyedPositions.length);
      eventManager.incrementProgress(EventType.score, _scoreController.lastScoreEvent?.pointsAdded ?? 0);
    }

    // 4. Gravity & Cascades (Transformed power-up stays intact on board, falls and settles)
    final allowedColors = _level.colorConfig?.availableColors ?? [];
    final cascadeResult = await _cascadeController.startCascade(allowedColors);
    if (cascadeResult.cascadeLevel > 0) {
      _goalController.onCascadeResult(cascadeResult);
      ServiceLocator.instance.dailyChallengeManager.incrementProgress(DailyChallengeType.cascade, cascadeResult.cascadeLevel);
      ServiceLocator.instance.eventManager.incrementProgress(EventType.cascade, cascadeResult.cascadeLevel);
    }

    if (_comboController.state.level > _highestCombo) {
      setState(() => _highestCombo = _comboController.state.level);
    }
    
    final comboEvent = ComboEvent(_comboController.state.level);
    ServiceLocator.instance.achievementManager.processEvent(comboEvent);
    ServiceLocator.instance.milestoneManager.processEvent(comboEvent);

    _levelResultController.setResolving(false);
  }

  /// Handles direct player tap interaction on an existing power-up block
  Future<void> _handlePowerUpTapActivation(Position pos) async {
    _levelResultController.setResolving(true);
    _moveController.consumeMove();

    final blastResult = await _powerUpManager.activatePowerUpAt(pos);

    if (blastResult.success) {
      if (blastResult.destroyedPositions.length > _largestBlast) {
        setState(() => _largestBlast = blastResult.destroyedPositions.length);
      }

      final blastEvent = BlockBlastEvent(blastResult.destroyedPositions.length, isMegaBlast: true);
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

      // Trigger cascades & gravity
      final allowedColors = _level.colorConfig?.availableColors ?? [];
      final cascadeResult = await _cascadeController.startCascade(allowedColors);
      if (cascadeResult.cascadeLevel > 0) {
        _goalController.onCascadeResult(cascadeResult);
        dailyManager.incrementProgress(DailyChallengeType.cascade, cascadeResult.cascadeLevel);
        eventManager.incrementProgress(EventType.cascade, cascadeResult.cascadeLevel);
      }

      if (_comboController.state.level > _highestCombo) {
        setState(() => _highestCombo = _comboController.state.level);
      }
    }

    _levelResultController.setResolving(false);
  }

  void _onPause() {
    if (_level.timeLimit != null) _timerController.stop();
    _levelResultController.setResolving(true);
    
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
        onQuit: () {
          Navigator.pop(context);
          Navigator.pop(context);
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
              
              RepaintBoundary(
                child: GoalPanel(goalController: _goalController),
              ),
              
              const SizedBox(height: 16),
              
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
                        _powerUpManager,
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
                    
                    Positioned.fill(
                      child: FeedbackLayer(feedbackController: _feedbackController),
                    ),

                    Positioned.fill(
                      child: BoosterTargetOverlay(targetController: _boosterTargetController),
                    ),

                    Positioned(
                      top: 20,
                      child: ComboDisplay(comboController: _comboController),
                    ),
                  ],
                ),
              ),
              
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
