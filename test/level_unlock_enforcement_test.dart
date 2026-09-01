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

    testWidgets('2. WorldMapScreen shows Locked state on play button for locked levels and prevents launching', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Initially level 1 is selected and unlocked
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.byType(AdventurePlayButton), findsOneWidget);

      // Find node for level 5 and tap it
      final level5Node = find.widgetWithText(LevelNode, '5');
      if (level5Node.evaluate().isNotEmpty) {
        await tester.tap(level5Node.first);
        await tester.pump(const Duration(milliseconds: 200));

        // Button should now show LOCKED state
        expect(find.text('LEVEL 5 (LOCKED)'), findsOneWidget);
        expect(find.byIcon(Icons.lock_rounded), findsWidgets);

        // Tap the locked play button -> should show locked warning SnackBar
        await tester.tap(find.byType(AdventurePlayButton));
        await tester.pump();

        expect(find.text('Level 5 is Locked! Complete Level 4 first.'), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 3));
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
