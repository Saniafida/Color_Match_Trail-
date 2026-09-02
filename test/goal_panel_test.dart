import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/screens/gameplay/widgets/goal_panel.dart';
import 'package:color_match_trail/game/goals/goal_controller.dart';
import 'package:color_match_trail/game/blocks/block_widget.dart';
import 'package:color_match_trail/game/blast/blast_result.dart';
import 'package:color_match_trail/models/models.dart';

void main() {
  testWidgets('GoalPanel displays real BlockWidget for target blocks', (WidgetTester tester) async {
    final goalController = GoalController();
    goalController.initialize([
      const GoalDefinition(
        id: 'goal_red',
        type: GoalType.clearColor,
        targetAmount: 15,
        color: BlockColor.red,
      ),
      const GoalDefinition(
        id: 'goal_blue',
        type: GoalType.clearColor,
        targetAmount: 20,
        color: BlockColor.blue,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalPanel(goalController: goalController),
        ),
      ),
    );

    // Verify BlockWidgets are rendered for the targets
    expect(find.byType(BlockWidget), findsNWidgets(2));
    expect(find.text('0 / 15'), findsOneWidget);
    expect(find.text('0 / 20'), findsOneWidget);

    // Verify the blocks have the correct colors
    final blockWidgets = tester.widgetList<BlockWidget>(find.byType(BlockWidget)).toList();
    expect(blockWidgets[0].block.color, equals(BlockColor.red));
    expect(blockWidgets[1].block.color, equals(BlockColor.blue));
  });

  testWidgets('GoalPanel keeps real block and shows completion badge when goal is completed', (WidgetTester tester) async {
    final goalController = GoalController();
    goalController.initialize([
      const GoalDefinition(
        id: 'goal_green',
        type: GoalType.clearColor,
        targetAmount: 5,
        color: BlockColor.green,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalPanel(goalController: goalController),
        ),
      ),
    );

    expect(find.byType(BlockWidget), findsOneWidget);
    expect(find.text('0 / 5'), findsOneWidget);

    // Simulate blasting 5 green blocks
    goalController.onBlastResult(
      const BlastResult(
        success: true,
        destroyedBlockIds: ['1', '2', '3', '4', '5'],
        destroyedCount: 5,
        color: BlockColor.green,
      ),
    );

    await tester.pumpAndSettle();

    // The real BlockWidget should STILL be present!
    expect(find.byType(BlockWidget), findsOneWidget);
    // Should show DONE text and completion check icon
    expect(find.text('DONE'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
