import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../game/board/board.dart';
import '../../game/board/board_widget.dart';
import '../../game/combo/combo_controller.dart';
import '../../game/score/score_controller.dart';
import '../../game/goals/goal_controller.dart';
import '../../game/moves/move_controller.dart';
import '../../core/services/timer/timer_controller.dart';
import '../../game/level_result/level_result_system.dart';
import '../../game/levels/initial_board_generator.dart';
import '../../game/gravity/gravity_controller.dart';
import '../../game/specials/special_controller.dart';
import '../../game/specials/special_creation_result.dart';
import '../../game/boosters/booster_use_state.dart';
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
import 'widgets/visual_fx/gameplay_fx_layer.dart';
import 'widgets/visual_fx/gameplay_fx_controller.dart';
import 'widgets/visual_fx/screen_shake_container.dart';
import '../../game/blocks/block_color_mapper.dart';
import '../tutorial/tutorial_overlay.dart';
import '../../widgets/dialogs/out_of_hearts_dialog.dart';

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

  final GameplayFxController _fxController = GameplayFxController();
  final ScreenShakeController _shakeController = ScreenShakeController();

  bool _isInitialized = false;
  int _highestCombo = 0;
  int _largestBlast = 0;
  double _currentCellSize = 48.0;

  Offset _getCellCenter(Position pos, [double? cellSize]) {
    final size = cellSize ?? _currentCellSize;
    return Offset((pos.column + 0.5) * size, (pos.row + 0.5) * size);
  }

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final livesManager = ServiceLocator.instance.livesManager;
    if (!livesManager.hasLives) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final refilled = await OutOfHeartsDialog.show(context);
        if (!refilled || !livesManager.hasLives) {
          if (mounted) {
            Navigator.pop(context);
          }
          return;
        }
      });
    }

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
      onMoveBlock: (id, pos) {
        final b = _blocks[id];
        if (b != null) {
          setState(() => _blocks[id] = b.copyWith(position: pos));
        }
      },
      specialController: _specialController,
    );

    _boosterManager.addListener(_onBoosterStateChanged);
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

    try {
      ServiceLocator.instance.audioManager.playGameplayBgm();
    } catch (_) {}

    setState(() {
      _isInitialized = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ServiceLocator.instance.tutorialManager.checkAndStartTutorial(widget.levelId);
    });
  }

  void _onBoosterStateChanged() {
    if (!mounted) return;
    if (_boosterManager.state == BoosterUseState.executing) {
      final def = _boosterManager.selectedBoosterDef;
      if (def?.type == BoosterType.shuffle) {
        ServiceLocator.instance.audioManager.playShuffle();
        final cellSize = _currentCellSize;
        for (int r = 0; r < _boardController.rows; r++) {
          for (int c = 0; c < _boardController.columns; c++) {
            final center = _getCellCenter(Position(r, c), cellSize);
            _fxController.spawnMatchPop(center, const Color(0xFFFFD54F), count: 3);
          }
        }
      } else if (def?.type == BoosterType.extraMoves) {
        ServiceLocator.instance.audioManager.playExtraMoves();
        _shakeController.shake(intensity: 3.5);
      }
    }
  }

  @override
  void dispose() {
    _boosterManager.removeListener(_onBoosterStateChanged);
    _boosterManager.dispose();
    _boosterTargetController.dispose();
    _fxController.dispose();
    _shakeController.dispose();
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
    final cellSize = _currentCellSize;
    final matchColor = BlockColorMapper.getStyle(trail.color!).main;

    if (isPowerUpCreation) {
      // Staggered pop sparkle particles along disappearing blocks
      for (int i = 0; i < trail.positions.length; i++) {
        final center = _getCellCenter(trail.positions[i], cellSize);
        Future.delayed(Duration(milliseconds: i * 15), () {
          if (mounted) _fxController.spawnMatchPop(center, matchColor, count: 8);
        });
      }

      // 2. Power-Up Transformation Flow (Block transforms, others disappear into it)
      final transformResult = await _powerUpManager.processTrailPowerUp(
        blockIds: trail.blockIds,
        positions: trail.positions,
        color: trail.color!,
      );

      // Celebration pulse & golden sparkle burst on creation cell
      if (transformResult.targetPosition != null) {
        final creationCenter = _getCellCenter(transformResult.targetPosition!, cellSize);
        _fxController.spawnPowerUpCreation(creationCenter, matchColor, transformResult.powerUpType);
      }

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
      dailyManager.onColorBlocksCleared(trail.color!, blastResult.destroyedPositions.length);
      dailyManager.incrementProgress(DailyChallengeType.clearBlocks, blastResult.destroyedPositions.length);
      dailyManager.incrementProgress(DailyChallengeType.createSpecial, 1);
      eventManager.incrementProgress(EventType.clearBlocks, blastResult.destroyedPositions.length);
      eventManager.incrementProgress(EventType.createSpecial, 1);

      _goalController.onSpecialCreation(SpecialCreationResult(
        created: true,
        type: transformResult.specialType,
      ));
    } else {
      // 3. Normal Blast (Length 2-3, staggered pops)
      for (int i = 0; i < trail.positions.length; i++) {
        final center = _getCellCenter(trail.positions[i], cellSize);
        Future.delayed(Duration(milliseconds: i * 20), () {
          if (mounted) _fxController.spawnMatchPop(center, matchColor, count: 12);
        });
      }

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
      dailyManager.onColorBlocksCleared(trail.color!, blastResult.destroyedPositions.length);
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
    final blockId = _boardController.getBlockId(pos);
    final block = (blockId != null) ? _blocks[blockId] : null;
    if (block == null || !block.isPowerUp || block.isLocked || block.isBeingDestroyed) {
      return;
    }

    _levelResultController.setResolving(true);
    _moveController.consumeMove();

    final cellSize = _currentCellSize;
    final center = _getCellCenter(pos, cellSize);
    final sourceColor = BlockColorMapper.getStyle(block.color).main;

    // Determine special type with fallback for block.type
    SpecialBlockType specialType = block.specialType;
    if (specialType == SpecialBlockType.none) {
      switch (block.type) {
        case BlockType.rocket:
          specialType = SpecialBlockType.crossBlast;
          break;
        case BlockType.bomb:
          specialType = SpecialBlockType.bomb;
          break;
        case BlockType.colorBomb:
          specialType = SpecialBlockType.colorSpecial;
          break;
        case BlockType.otherSpecial:
          specialType = SpecialBlockType.magicWand;
          break;
        default:
          specialType = SpecialBlockType.smallArea;
          break;
      }
    }

    // Trigger Theme-Matched Blast FX
    _fxController.spawnPowerUpBlast(
      center: center,
      specialType: specialType,
      sourceColor: sourceColor,
    );

    // Directional Rocket / Cross Blast streaks
    if (specialType == SpecialBlockType.smallArea ||
        specialType == SpecialBlockType.horizontalLine ||
        specialType == SpecialBlockType.verticalLine ||
        specialType == SpecialBlockType.crossBlast) {
      final boardWidth = cellSize * _level.boardConfig.columns;
      final boardHeight = cellSize * _level.boardConfig.rows;

      if (specialType == SpecialBlockType.horizontalLine ||
          specialType == SpecialBlockType.crossBlast ||
          specialType == SpecialBlockType.smallArea) {
        _fxController.spawnRocketStreak(
          start: Offset(0, center.dy),
          end: Offset(boardWidth, center.dy),
          color: const Color(0xFFFF3D00),
          isHorizontal: true,
        );
      }
      if (specialType == SpecialBlockType.verticalLine ||
          specialType == SpecialBlockType.crossBlast) {
        _fxController.spawnRocketStreak(
          start: Offset(center.dx, 0),
          end: Offset(center.dx, boardHeight),
          color: const Color(0xFFFF3D00),
          isHorizontal: false,
        );
      }
    }

    // Subtle Screen Shake & Sound for impact
    if (specialType == SpecialBlockType.bomb ||
        specialType == SpecialBlockType.megaBomb) {
      _shakeController.shake(
        intensity: specialType == SpecialBlockType.megaBomb ? 10.0 : 6.5,
      );
      ServiceLocator.instance.audioManager.playBomb();
    } else if (specialType == SpecialBlockType.crossBlast ||
               specialType == SpecialBlockType.smallArea ||
               specialType == SpecialBlockType.horizontalLine ||
               specialType == SpecialBlockType.verticalLine) {
      _shakeController.shake(intensity: 4.5);
      ServiceLocator.instance.audioManager.playLineBlast();
    } else if (specialType == SpecialBlockType.colorSpecial) {
      _shakeController.shake(intensity: 7.0);
      ServiceLocator.instance.audioManager.playColorBomb();
    } else {
      ServiceLocator.instance.audioManager.playHammer();
    }

    final blastResult = await _powerUpManager.activatePowerUpAt(pos);

    if (blastResult.success) {
      if (blastResult.destroyedPositions.length > _largestBlast) {
        setState(() => _largestBlast = blastResult.destroyedPositions.length);
      }

      // Staggered outward pops on all affected blocks
      for (int i = 0; i < blastResult.destroyedPositions.length; i++) {
        final p = blastResult.destroyedPositions[i];
        final popCenter = _getCellCenter(p, cellSize);
        Future.delayed(Duration(milliseconds: (i * 12).clamp(0, 120)), () {
          if (mounted) {
            _fxController.spawnMatchPop(
              popCenter,
              blastResult.color != null
                  ? BlockColorMapper.getStyle(blastResult.color!).main
                  : const Color(0xFFFFD700),
              count: 6,
            );
          }
        });
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

  /// Handles player tapping a target cell when a booster is selected from the bottom bar
  Future<void> _handleBoosterTapActivation(Position pos) async {
    final def = _boosterManager.selectedBoosterDef;
    if (def == null) {
      _boosterTargetController.cancel();
      return;
    }

    final blockId = _boardController.getBlockId(pos);
    final block = (blockId != null) ? _blocks[blockId] : null;
    if (block == null || block.isLocked) {
      // Don't cancel targeting on accidental miss; allow player to tap a valid block
      return;
    }

    _levelResultController.setResolving(true);
    final cellSize = _currentCellSize;
    final center = _getCellCenter(pos, cellSize);
    final blockColor = BlockColorMapper.getStyle(block.color).main;

    final activeCombo = _boosterManager.activeCombination;
    if (activeCombo != null) {
      // Combo Visual Effects
      _fxController.spawnPowerUpBlast(
        center: center,
        specialType: SpecialBlockType.megaBomb,
        sourceColor: const Color(0xFFFFD700),
      );
      _shakeController.shake(intensity: 9.0);
      ServiceLocator.instance.audioManager.playBomb();
    } else {
      // 1. Trigger Theme-Matched Blast FX per Booster Type
      switch (def.type) {
        case BoosterType.rowClear: // Rocket (Clears row & column)
          final boardWidth = cellSize * _level.boardConfig.columns;
          final boardHeight = cellSize * _level.boardConfig.rows;
          _fxController.spawnRocketStreak(
            start: Offset(0, center.dy),
            end: Offset(boardWidth, center.dy),
            color: const Color(0xFFFF4500),
            isHorizontal: true,
          );
          _fxController.spawnRocketStreak(
            start: Offset(center.dx, 0),
            end: Offset(center.dx, boardHeight),
            color: const Color(0xFFFF4500),
            isHorizontal: false,
          );
          _fxController.spawnPowerUpBlast(
            center: center,
            specialType: SpecialBlockType.crossBlast,
            sourceColor: blockColor,
          );
          _shakeController.shake(intensity: 6.0);
          ServiceLocator.instance.audioManager.playLineBlast();
          break;

        case BoosterType.areaBlast: // Bomb (3x3 explosive radius)
          _fxController.spawnPowerUpBlast(
            center: center,
            specialType: SpecialBlockType.bomb,
            sourceColor: const Color(0xFFFF6F00),
          );
          _shakeController.shake(intensity: 8.5);
          ServiceLocator.instance.audioManager.playBomb();
          break;

        case BoosterType.colorClear: // Disco Ball / Color Bomb (All same color)
          _fxController.spawnPowerUpBlast(
            center: center,
            specialType: SpecialBlockType.colorSpecial,
            sourceColor: blockColor,
          );
          for (int r = 0; r < _boardController.rows; r++) {
            for (int c = 0; c < _boardController.columns; c++) {
              final p = Position(r, c);
              final id = _boardController.getBlockId(p);
              if (id != null && _blocks[id]?.color == block.color) {
                final cellCenter = _getCellCenter(p, cellSize);
                _fxController.spawnMatchPop(cellCenter, blockColor, count: 6);
              }
            }
          }
          _shakeController.shake(intensity: 7.5);
          ServiceLocator.instance.audioManager.playColorBomb();
          break;

        case BoosterType.hammer: // Hammer single block smash
          _fxController.spawnPowerUpBlast(
            center: center,
            specialType: SpecialBlockType.smallArea,
            sourceColor: const Color(0xFFFFD700),
          );
          _shakeController.shake(intensity: 4.5);
          ServiceLocator.instance.audioManager.playHammer();
          break;

        default:
          break;
      }
    }

    // 2. Execute targeted booster logic
    final result = await _boosterManager.executeTargetedBooster(pos);

    if (result.success) {
      final affected = result.affectedPositions;
      if (affected.length > _largestBlast) {
        setState(() => _largestBlast = affected.length);
      }

      if (result.blastResult != null) {
        final blastResult = result.blastResult!;
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

      // Staggered outward pops on all affected cells
      for (int i = 0; i < affected.length; i++) {
        final p = affected[i];
        final popCenter = _getCellCenter(p, cellSize);
        Future.delayed(Duration(milliseconds: (i * 12).clamp(0, 120)), () {
          if (mounted) {
            _fxController.spawnMatchPop(
              popCenter,
              blockColor,
              count: 6,
            );
          }
        });
      }

      // 3. Trigger cascades and gravity drop
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
        onRestart: () async {
          Navigator.pop(context);
          final livesManager = ServiceLocator.instance.livesManager;
          if (!livesManager.hasLives) {
            final refilled = await OutOfHeartsDialog.show(context);
            if (!refilled || !livesManager.hasLives) return;
          }
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.gameplay, arguments: widget.levelId);
          }
        },
        onExit: () {
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),
          // 2. Dark board contrast overlay
          Container(
            color: const Color(0xFF1E2A38).withAlpha(220),
          ),
          // 3. Gameplay Content
          SafeArea(
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Dynamically calculate cellSize to fit both width & height comfortably with padding
                        final maxAvailableWidth = constraints.maxWidth - 24;
                        final maxAvailableHeight = constraints.maxHeight - 24;
                        final cellSizeByW = (maxAvailableWidth - 24) / _level.boardConfig.columns;
                        final cellSizeByH = (maxAvailableHeight - 24) / _level.boardConfig.rows;
                        final cellSize = (cellSizeByW < cellSizeByH ? cellSizeByW : cellSizeByH).clamp(32.0, 72.0);
                        _currentCellSize = cellSize;

                        return AnimatedBuilder(
                          animation: Listenable.merge([
                            _levelResultController,
                            _cascadeController,
                            _trailController,
                            _gravityController,
                            _powerUpManager,
                            _boosterManager,
                          ]),
                          builder: (context, child) {
                            final isLocked = _levelResultController.status != GameStatus.playing ||
                                             _cascadeController.inputLocked;

                            return AbsorbPointer(
                              absorbing: isLocked,
                              child: ScreenShakeContainer(
                                controller: _shakeController,
                                child: Center(
                                  child: BoardWidget(
                                    board: renderBoard,
                                    trail: _trailController.activeTrail,
                                    cellSize: cellSize,
                                    cellSpacing: 0.0,
                                    fxOverlay: GameplayFxLayer(controller: _fxController),
                                    onDragStart: (pos) {
                                      if (_boosterTargetController.isTargeting) {
                                        _handleBoosterTapActivation(pos);
                                        return;
                                      }
                                      if (!TutorialValidator.canStartDrag(ServiceLocator.instance.tutorialManager, pos, _boardController)) return;
                                      _trailController.handleDragStart(pos);
                                      if (_trailController.isDragging) {
                                        ServiceLocator.instance.audioManager.playTileTap();
                                      }
                                    },
                                    onDragUpdate: (pos) {
                                      if (_boosterTargetController.isTargeting) return;
                                      final prevLength = _trailController.activeTrail.positions.length;
                                      _trailController.handleDragUpdate(pos);
                                      final newLength = _trailController.activeTrail.positions.length;
                                      if (newLength > prevLength) {
                                        ServiceLocator.instance.audioManager.playTrailDrag(trailLength: newLength);
                                      }
                                    },
                                    onDragEnd: () {
                                      if (_boosterTargetController.isTargeting) return;
                                      _trailController.handleDragEnd();
                                    },
                                    onDragCancel: () {
                                      if (_boosterTargetController.isTargeting) return;
                                      _trailController.handleDragCancel();
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
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
                child: BoosterBar(
                  boosterManager: _boosterManager,
                  levelResultController: _levelResultController,
                  blastController: _blastController,
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
