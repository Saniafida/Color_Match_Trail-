import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/game/board/board.dart';
import 'package:color_match_trail/game/blast/blast.dart';
import 'package:color_match_trail/game/specials/special.dart';
import 'package:color_match_trail/game/specials/power_up_manager.dart';
import 'package:color_match_trail/game/boosters/booster_manager.dart';
import 'package:color_match_trail/game/boosters/booster_target_controller.dart';
import 'package:color_match_trail/game/boosters/booster_use_state.dart';
import 'package:color_match_trail/game/moves/move_controller.dart';
import 'package:color_match_trail/game/level_result/level_result_system.dart';
import 'package:color_match_trail/game/goals/goal_controller.dart';
import 'package:color_match_trail/game/score/score_controller.dart';
import 'package:color_match_trail/game/combo/combo_controller.dart';
import 'package:color_match_trail/game/levels/board_config.dart' as level_cfg;
import 'package:color_match_trail/core/services/timer/timer_controller.dart';
import 'package:color_match_trail/core/services/service_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ServiceLocator.instance.initialize();
  });

  group('Booster and PowerUp Reliability Fix Tests', () {
    late BoardController boardController;
    late Map<String, Block> blocks;
    late SpecialController specialController;
    late BlastController blastController;
    late MoveController moveController;
    late GoalController goalController;
    late TimerController timerController;
    late ComboController comboController;
    late ScoreController scoreController;
    late LevelResultController levelResultController;
    late BoosterManager boosterManager;
    late BoosterTargetController boosterTargetController;
    late PowerUpManager powerUpManager;

    setUp(() {
      boardController = BoardController(rows: 6, columns: 6);
      blocks = {};

      for (int r = 0; r < 6; r++) {
        for (int c = 0; c < 6; c++) {
          final pos = Position(r, c);
          final id = 'b_${r}_$c';
          final block = Block(id: id, color: BlockColor.blue, position: pos);
          blocks[id] = block;
          boardController.setBlockId(pos, id);
        }
      }

      moveController = MoveController()..initialize(25);
      goalController = GoalController()..initialize([]);
      timerController = TimerController()..initialize(null);
      comboController = ComboController();
      scoreController = ScoreController(comboController: comboController);

      const levelDef = LevelDefinition(
        id: 1,
        movesLimit: 25,
        boardConfig: level_cfg.BoardConfig(rows: 6, columns: 6),
      );

      levelResultController = LevelResultController(
        winCondition: WinConditionController(goalController: goalController, winRule: WinRule.allRequiredGoalsCompleted),
        loseCondition: LoseConditionController(moveController: moveController, timerController: timerController, loseRule: LoseRule.movesOrTimeExhausted),
        moveController: moveController,
        timerController: timerController,
        goalController: goalController,
        scoreController: scoreController,
        levelDefinition: levelDef,
      );
      levelResultController.startGame();

      specialController = SpecialController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
      );

      blastController = BlastController(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (b) => blocks[b.id] = b,
        onRemoveBlock: (id) => blocks.remove(id),
        specialController: specialController,
      );

      powerUpManager = PowerUpManager(
        boardController: boardController,
        getBlock: (id) => blocks[id],
        onUpdateBlock: (b) => blocks[b.id] = b,
        onRemoveBlock: (id) => blocks.remove(id),
        specialController: specialController,
        blastController: blastController,
      );

      boosterManager = BoosterManager(
        boardController: boardController,
        blastController: blastController,
        moveController: moveController,
        levelResultController: levelResultController,
        storage: ServiceLocator.instance.storage,
        getBlock: (id) => blocks[id],
        onMoveBlock: (id, pos) {
          if (blocks.containsKey(id)) {
            blocks[id] = blocks[id]!.copyWith(position: pos);
          }
        },
        specialController: specialController,
      );

      boosterTargetController = BoosterTargetController(
        boosterManager: boosterManager,
        isValidTarget: (pos) => boardController.isValidPosition(pos) && boardController.getBlockId(pos) != null,
      );
    });

    tearDown(() {
      boosterTargetController.dispose();
      boosterManager.dispose();
      levelResultController.dispose();
      blastController.dispose();
    });

    test('1. Instant booster (Shuffle) executes immediately when switched from targeted booster (Hammer)', () async {
      // 1. First select Hammer
      boosterManager.selectBooster(BoosterType.hammer);
      expect(boosterManager.state, BoosterUseState.selecting);
      expect(boosterManager.selectedBoosterDef?.type, BoosterType.hammer);
      expect(boosterTargetController.isTargeting, isTrue);

      // 2. Switch directly to Shuffle (instant booster)
      boosterManager.selectBooster(BoosterType.shuffle);
      
      // Wait for shuffle execution to complete
      await Future.delayed(const Duration(milliseconds: 600));

      // Should execute and return to idle
      expect(boosterManager.selectedBoosterDef, isNull);
      expect(boosterTargetController.isTargeting, isFalse);
    });

    test('2. Instant booster (+5 Moves) adds moves when switched from targeted booster', () async {
      final initialMoves = moveController.currentMoves;
      boosterManager.selectBooster(BoosterType.rowClear);
      expect(boosterManager.state, BoosterUseState.selecting);

      boosterManager.selectBooster(BoosterType.extraMoves);
      await Future.delayed(const Duration(milliseconds: 400));
      expect(moveController.currentMoves, initialMoves + 5);
      expect(boosterManager.selectedBoosterDef, isNull);
    });

    test('3. BoosterTargetController keeps isTargeting true when selecting a combo', () async {
      // Select first booster (rowClear)
      boosterManager.selectBooster(BoosterType.rowClear);
      expect(boosterManager.state, BoosterUseState.selecting);
      expect(boosterTargetController.isTargeting, isTrue);

      // Select second booster (areaBlast) -> combo
      boosterManager.selectBooster(BoosterType.areaBlast);
      expect(boosterManager.state, BoosterUseState.selectingCombo);
      // TARGETING MUST REMAIN TRUE FOR COMBOS!
      expect(boosterTargetController.isTargeting, isTrue);
      expect(boosterManager.activeCombination, isNotNull);

      // Tap on target board cell to execute combo
      final result = await boosterManager.executeTargetedBooster(const Position(2, 2));
      expect(result.success, isTrue);
      expect(boosterManager.selectedBoosterDef, isNull);
    });

    test('4. activatePowerUpAt falls back cleanly from BlockType to SpecialBlockType and fires', () async {
      // Create a rocket block where specialType was none but type is rocket
      final pos = const Position(2, 2);
      final id = boardController.getBlockId(pos)!;
      blocks[id] = blocks[id]!.copyWith(type: BlockType.rocket, specialType: SpecialBlockType.none);

      final result = await powerUpManager.activatePowerUpAt(pos);
      expect(result.success, isTrue);
      expect(result.destroyedPositions.isNotEmpty, isTrue);
    });

    test('5. processTrailPowerUp creates new power-up and detonates consumed specials in trail', () async {
      // Create a trail of 5 blocks where (0, 1) is already a bomb
      final trailPositions = [
        const Position(0, 0),
        const Position(0, 1),
        const Position(0, 2),
        const Position(0, 3),
        const Position(0, 4),
      ];
      final trailBlockIds = trailPositions.map((p) => boardController.getBlockId(p)!).toList();
      final bombId = trailBlockIds[1];
      blocks[bombId] = blocks[bombId]!.copyWith(specialType: SpecialBlockType.bomb);

      final transformResult = await powerUpManager.processTrailPowerUp(
        blockIds: trailBlockIds,
        positions: trailPositions,
        color: BlockColor.blue,
      );

      expect(transformResult.transformed, isTrue);
      expect(transformResult.targetPosition, isNotNull);
    });
  });
}
