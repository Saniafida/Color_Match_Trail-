import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/screens/world_map/world_map_screen.dart';
import 'package:color_match_trail/screens/world_map/widgets/level_node.dart';
import 'package:color_match_trail/screens/world_map/widgets/adventure_play_button.dart';
import 'package:color_match_trail/core/services/service_locator.dart';
import 'package:color_match_trail/game/progression/progression_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.instance.initialize();
  });

  group('Level Unlock & Lock Enforcement Tests', () {
    late ProgressionManager progressionManager;

    setUp(() {
      progressionManager = ServiceLocator.instance.progressionManager;
      progressionManager.resetProgression();
    });

    testWidgets('1. Level 1 is unlocked initially while Level 2, 3, etc. are locked', (WidgetTester tester) async {
      expect(progressionManager.canPlayLevel('level_1'), isTrue);
      expect(progressionManager.canPlayLevel('level_2'), isFalse);
      expect(progressionManager.canPlayLevel('level_10'), isFalse);
    });

    testWidgets('2. Locked level nodes cannot be clicked and selection remains on unlocked level', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Initially level 1 is selected and unlocked
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.byType(AdventurePlayButton), findsOneWidget);

      // Find node for level 5 and tap it -> locked levels should not be clickable
      final level5Node = find.widgetWithText(LevelNode, '5');
      if (level5Node.evaluate().isNotEmpty) {
        await tester.tap(level5Node.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));

        // Button should still show LEVEL 1 (level 5 was locked and not clickable)
        expect(find.text('LEVEL 1'), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('3. Completing level 1 unlocks level 2', (WidgetTester tester) async {
      expect(progressionManager.canPlayLevel('level_2'), isFalse);

      await progressionManager.saveLevelResult(
        levelId: 'level_1',
        score: 1500,
        stars: 3,
        movesUsed: 10,
        highestCombo: 2,
        completed: true,
      );

      expect(progressionManager.canPlayLevel('level_2'), isTrue);
      expect(progressionManager.canPlayLevel('level_3'), isFalse);

      await tester.pump(const Duration(seconds: 3));
    });
  });
}
