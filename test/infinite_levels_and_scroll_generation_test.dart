import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/levels/adventure_level_generator.dart';
import 'package:color_match_trail/game/progression/progression_manager.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/screens/world_map/widgets/adventure_board.dart';
import 'package:color_match_trail/screens/world_map/widgets/level_node.dart';
import 'package:color_match_trail/game/progression/level_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.instance.initialize();
  });

  group('Infinite Levels System Tests', () {
    late ProgressionManager progManager;

    setUp(() {
      progManager = ServiceLocator.instance.progressionManager;
      progManager.resetProgression();
    });

    test('1. Generator procedurally produces rich, valid configurations for infinite levels', () {
      final testLevelNumbers = [134, 135, 147, 150, 180, 200, 350, 500, 1000];

      for (final lvlNum in testLevelNumbers) {
        final level = AdventureLevelGenerator.generateLevel(lvlNum);
        expect(level.id, equals(lvlNum));
        expect(level.boardConfig.rows, inInclusiveRange(6, 8));
        expect(level.boardConfig.columns, inInclusiveRange(6, 8));
        expect(level.movesLimit, isNotNull);
        expect(level.movesLimit!, inInclusiveRange(20, 45));
        expect(level.goals.isNotEmpty, isTrue);
        expect(level.colorConfig?.availableColors.isNotEmpty, isTrue);

        final data = AdventureLevelGenerator.generateData(lvlNum);
        expect(data.levelId, equals('level_$lvlNum'));
        expect(data.starThresholds.length, equals(3));
        expect(data.starThresholds[0] < data.starThresholds[1], isTrue);
        expect(data.starThresholds[1] < data.starThresholds[2], isTrue);

        // Every 10th level is a boss level
        if (lvlNum % 10 == 0) {
          expect(data.difficulty, equals('expert'));
        }
      }
    });

    test('2. World themes cycle seamlessly across infinite levels', () {
      final worldThemesCount = AdventureLevelGenerator.worldThemes.length;
      expect(worldThemesCount, equals(15));

      final world1 = AdventureLevelGenerator.generateWorld(1);
      expect(world1.worldId, equals('world_1'));
      expect(world1.levelIds.first, equals('level_1'));
      expect(world1.levelIds.last, equals('level_10'));

      // World 16 should cycle back to Theme 1 with Title suffix ' 2'
      final world16 = AdventureLevelGenerator.generateWorld(16);
      expect(world16.worldId, equals('world_16'));
      expect(world16.titleKey, contains('2'));
      expect(world16.levelIds.first, equals('level_151'));
      expect(world16.levelIds.last, equals('level_160'));
    });

    test('3. ProgressionManager unlocks levels beyond 134 and 147 sequentially to infinity', () async {
      // Complete level 134 -> level 135 must be unlocked!
      await progManager.saveLevelResult(
        levelId: 'level_134',
        score: 50000,
        stars: 3,
        movesUsed: 15,
        highestCombo: 3,
        completed: true,
      );

      expect(progManager.canPlayLevel('level_135'), isTrue,
          reason: 'Completing level 134 must sequentially unlock level 135');

      // Complete level 135 -> level 136 must be unlocked!
      await progManager.saveLevelResult(
        levelId: 'level_135',
        score: 52000,
        stars: 3,
        movesUsed: 14,
        highestCombo: 2,
        completed: true,
      );

      expect(progManager.canPlayLevel('level_136'), isTrue,
          reason: 'Completing level 135 must sequentially unlock level 136');

      // Complete level 147 -> level 148 must unlock beyond previous 147 cap!
      await progManager.saveLevelResult(
        levelId: 'level_147',
        score: 60000,
        stars: 3,
        movesUsed: 18,
        highestCombo: 4,
        completed: true,
      );

      expect(progManager.canPlayLevel('level_148'), isTrue,
          reason: 'Completing level 147 must sequentially unlock level 148');
    });

    testWidgets('4. AdventureBoard displays beyond level 134 and allows selecting higher levels',
        (WidgetTester tester) async {
      int selected = 1;
      final Map<String, LevelProgress> progressMap = {
        'level_1': const LevelProgress(levelId: 'level_1', unlocked: true, completed: true, bestStars: 3, bestScore: 1000),
        'level_134': const LevelProgress(levelId: 'level_134', unlocked: true, completed: true, bestStars: 3, bestScore: 20000),
        'level_135': const LevelProgress(levelId: 'level_135', unlocked: true, completed: false, bestStars: 0, bestScore: 0),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: AdventureBoard(
                progressMap: progressMap,
                selectedLevel: 135,
                totalLevels: 174,
                onSelectLevel: (lvl) {
                  selected = lvl;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Find node for level 135
      final node135 = find.widgetWithText(LevelNode, '135');
      expect(node135, findsOneWidget, reason: 'Level 135 must be rendered on the board');

      // Scroll so node 135 at the top is cleanly centered below the wooden banner
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(100.0);
      await tester.pump(const Duration(milliseconds: 100));

      // Tap level 135 node
      await tester.tap(node135, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      expect(selected, equals(135), reason: 'Tapping unlocked level 135 node must select it');
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('5. Scrolling UP in AdventureBoard dynamically triggers level generation beyond initial levels',
        (WidgetTester tester) async {
      final Map<String, LevelProgress> progressMap = {
        'level_1': const LevelProgress(levelId: 'level_1', unlocked: true, completed: false, bestStars: 0, bestScore: 0),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: AdventureBoard(
                progressMap: progressMap,
                selectedLevel: 1,
                totalLevels: 134,
                onSelectLevel: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Initially level 134 exists
      expect(find.widgetWithText(LevelNode, '134'), findsOneWidget);

      // Now scroll UP towards the top of the map (drag down by 6000 to reach top)
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 6000));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // After scrolling to the summit, higher levels (135+) should be dynamically generated
      final level140 = find.widgetWithText(LevelNode, '140');
      expect(level140, findsOneWidget, reason: 'Auto-generation must generate levels above 134 upon scrolling up');
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
