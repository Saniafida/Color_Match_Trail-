import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_match_trail/game/mini_games/mini_game_progress_manager.dart';
import 'package:color_match_trail/screens/mini_games/tile_sort_screen.dart';
import 'package:color_match_trail/screens/mini_games/tile_stack_screen.dart';
import 'package:color_match_trail/screens/mini_games/tile_drop_screen.dart';
import 'package:color_match_trail/screens/mini_games/tile_swap_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MiniGameProgressManager.instance.initialize();
    await MiniGameProgressManager.instance.resetAll();
  });

  group('MiniGameProgressManager Unit Tests', () {
    test('Default levels start at Level 1 for all mini games', () {
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileSort), 1);
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileStack), 1);
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileDrop), 1);
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileSwap), 1);
    });

    test('Saving level 5 persists across getLevel and SharedPreferences', () async {
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSort, 5);
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileSort), 5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('minigame_tile_sort_level'), 5);
    });

    test('Re-initializing loads persisted levels from storage', () async {
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSort, 4);
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileStack, 5);
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileDrop, 3);
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSwap, 7);

      // Re-initialize as if app was reopened
      await MiniGameProgressManager.instance.initialize();

      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileSort), 4);
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileStack), 5);
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileDrop), 3);
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileSwap), 7);
    });

    test('Does not downgrade unlocked levels on lower level replay', () async {
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSort, 5);
      // Attempting to save level 2 (replaying level 2)
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSort, 2);

      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileSort), 5);
    });

    test('resetAll resets all games back to level 1', () async {
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSort, 5);
      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileStack, 6);

      await MiniGameProgressManager.instance.resetAll();

      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileSort), 1);
      expect(MiniGameProgressManager.instance.getLevel(MiniGameProgressManager.tileStack), 1);
    });
  });

  group('Mini-Game Screens Level Restoration Tests', () {
    testWidgets('TileSortScreen resumes from saved level', (tester) async {
      tester.view.physicalSize = const Size(450, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSort, 4);

      await tester.pumpWidget(
        const MaterialApp(
          home: TileSortScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('TILE SORT • LV. 4'), findsOneWidget);
    });

    testWidgets('TileStackScreen resumes from saved level', (tester) async {
      tester.view.physicalSize = const Size(450, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileStack, 5);

      await tester.pumpWidget(
        const MaterialApp(
          home: TileStackScreen(),
        ),
      );
      await tester.pump();

      expect(find.textContaining('LV.5'), findsWidgets);
    });

    testWidgets('TileDropScreen resumes from saved level', (tester) async {
      tester.view.physicalSize = const Size(450, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileDrop, 3);

      await tester.pumpWidget(
        const MaterialApp(
          home: TileDropScreen(),
        ),
      );
      await tester.pump();

      expect(find.textContaining('LVL 3'), findsWidgets);
    });

    testWidgets('TileSwapScreen resumes from saved level', (tester) async {
      tester.view.physicalSize = const Size(450, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSwap, 6);

      await tester.pumpWidget(
        const MaterialApp(
          home: TileSwapScreen(),
        ),
      );
      await tester.pump();

      expect(find.textContaining('LVL 6'), findsWidgets);
    });

    testWidgets('Explicit startingLevel parameter overrides saved level', (tester) async {
      tester.view.physicalSize = const Size(450, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await MiniGameProgressManager.instance.saveLevel(MiniGameProgressManager.tileSort, 10);

      await tester.pumpWidget(
        const MaterialApp(
          home: TileSortScreen(startingLevel: 2),
        ),
      );
      await tester.pump();

      expect(find.text('TILE SORT • LV. 2'), findsOneWidget);
    });
  });
}
