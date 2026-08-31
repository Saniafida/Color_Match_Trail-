import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/screens/world_map/world_map_screen.dart';
import 'package:color_match_trail/screens/world_map/widgets/level_node.dart';
import 'package:color_match_trail/screens/world_map/widgets/world_header.dart';
import 'package:color_match_trail/screens/world_map/widgets/world_progress.dart';
import 'package:color_match_trail/screens/world_map/widgets/world_navigation.dart';
import 'package:color_match_trail/screens/level_select/level_select_screen.dart';
import 'package:color_match_trail/models/world_definition.dart';
import 'package:color_match_trail/game/progression/world_progress.dart';
import 'package:color_match_trail/game/progression/level_progress.dart';
import 'package:color_match_trail/core/services/service_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ServiceLocator.instance.initialize();
  });

  group('Module 54 World Map & Widgets Widget Tests', () {
    testWidgets('1. LevelNode renders correctly in different states', (WidgetTester tester) async {
      bool tapped = false;

      // Render Unlocked Node
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelNode(
              progress: const LevelProgress(
                levelId: 'level_1',
                unlocked: true,
                completed: false,
                bestScore: 0,
                bestStars: 0,
              ),
              isCurrent: true,
              reducedMotion: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byType(LevelNode));
      expect(tapped, isTrue);

      // Render Completed Node with 3 Stars
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelNode(
              progress: const LevelProgress(
                levelId: 'level_2',
                unlocked: true,
                completed: true,
                bestScore: 2500,
                bestStars: 3,
              ),
              isCurrent: false,
              reducedMotion: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));

      // Render Locked Node (should display Lock icon)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelNode(
              progress: const LevelProgress(
                levelId: 'level_5',
                unlocked: false,
                completed: false,
                bestScore: 0,
                bestStars: 0,
              ),
              isCurrent: false,
              reducedMotion: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('2. WorldHeader displays world name and stars', (WidgetTester tester) async {
      const world = WorldDefinition(
        worldId: 'world_1',
        titleKey: 'Color Meadows',
        descriptionKey: 'Begin your journey across vibrant fields.',
        levelIds: ['level_1', 'level_2'],
      );

      const progress = WorldProgress(
        worldId: 'world_1',
        unlocked: true,
        completed: false,
        completedLevels: 1,
        totalLevels: 2,
        stars: 3,
        maxStars: 6,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorldHeader(
              world: world,
              progress: progress,
              totalCampaignStars: 3,
            ),
          ),
        ),
      );

      expect(find.text('Color Meadows'), findsOneWidget);
      expect(find.text('3/6'), findsOneWidget);
    });

    testWidgets('3. WorldProgressWidget renders completion percentage', (WidgetTester tester) async {
      const progress = WorldProgress(
        worldId: 'world_1',
        unlocked: true,
        completed: false,
        completedLevels: 2,
        totalLevels: 5,
        stars: 6,
        maxStars: 15,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorldProgressWidget(progress: progress),
          ),
        ),
      );

      expect(find.text('2/5 Levels (40%)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('4. WorldNavigation switches worlds and displays lock indicators', (WidgetTester tester) async {
      final worlds = [
        const WorldDefinition(worldId: 'world_1', titleKey: 'World 1', descriptionKey: '', levelIds: ['level_1']),
        const WorldDefinition(worldId: 'world_2', titleKey: 'World 2', descriptionKey: '', levelIds: ['level_2']),
      ];

      int selectedIdx = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldNavigation(
              worlds: worlds,
              selectedIndex: 0,
              onWorldSelected: (idx) => selectedIdx = idx,
              getWorldProgress: (id) => WorldProgress(
                worldId: id,
                unlocked: id == 'world_1',
                completed: false,
                completedLevels: 0,
                totalLevels: 1,
                stars: 0,
                maxStars: 3,
              ),
            ),
          ),
        ),
      );

      expect(find.text('World 1'), findsOneWidget);
      expect(find.text('World 2'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      await tester.tap(find.text('World 2'));
      expect(selectedIdx, equals(1));
    });

    testWidgets('5. WorldMapScreen builds and displays successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorldMapScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ADVENTURE'), findsOneWidget);
      expect(find.byType(LevelNode), findsWidgets);
    });

    testWidgets('6. LevelSelectScreen builds and displays grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LevelSelectScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Select Level'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
