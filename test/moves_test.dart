import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/moves/moves.dart';

void main() {
  group('MoveController Tests', () {
    late MoveController controller;

    setUp(() {
      controller = MoveController(lowMovesThreshold: 3);
    });

    test('TEST 1: Unlimited moves', () {
      controller.initialize(null);
      expect(controller.state.mode, MoveMode.unlimitedMoves);
      expect(controller.hasMoves, isTrue);

      controller.consumeMove(source: MoveSource.playerMatch);
      expect(controller.currentMoves, 0);
      expect(controller.hasMoves, isTrue);
    });

    test('TEST 2: Limited moves initialization', () {
      controller.initialize(5);
      expect(controller.state.mode, MoveMode.limitedMoves);
      expect(controller.currentMoves, 5);
      expect(controller.hasMoves, isTrue);
      expect(controller.state.isLowMoves, isFalse);
    });

    test('TEST 3: Consume moves', () {
      controller.initialize(5);
      controller.consumeMove(source: MoveSource.playerMatch);
      expect(controller.currentMoves, 4);
    });

    test('TEST 4: Low moves threshold', () {
      controller.initialize(4);
      expect(controller.state.isLowMoves, isFalse);
      
      bool lowEventFired = false;
      controller.onLowMoves.listen((_) => lowEventFired = true);

      controller.consumeMove(source: MoveSource.playerMatch); // down to 3
      expect(controller.state.isLowMoves, isTrue);
      expect(lowEventFired, isTrue);
    });

    test('TEST 5: Zero moves prevents negative', () {
      controller.initialize(1);
      controller.consumeMove();
      expect(controller.currentMoves, 0);
      expect(controller.hasMoves, isFalse);
      
      controller.consumeMove(); // Should not go negative
      expect(controller.currentMoves, 0);
    });

    test('TEST 6: Reset moves', () {
      controller.initialize(5);
      controller.consumeMove();
      expect(controller.currentMoves, 4);
      
      controller.resetMoves();
      expect(controller.currentMoves, 5);
    });
  });
}
