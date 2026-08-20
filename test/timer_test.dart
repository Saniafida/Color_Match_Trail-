import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/core/services/timer/timer.dart';

void main() {
  group('TimerController Tests', () {
    late TimerController controller;

    setUp(() {
      controller = TimerController(lowTimeThreshold: 2);
    });

    test('TEST 1: Timer None mode', () {
      controller.initialize(null);
      expect(controller.state.mode, TimerMode.none);
      controller.start();
      expect(controller.state.isRunning, isFalse);
    });

    test('TEST 2: Timer countdown initialization', () {
      controller.initialize(60);
      expect(controller.state.mode, TimerMode.countdown);
      expect(controller.state.remainingSeconds, 60);
      expect(controller.state.isRunning, isFalse);
    });

    test('TEST 3: Timer pause and resume', () {
      controller.initialize(60);
      controller.start();
      expect(controller.state.isRunning, isTrue);
      
      controller.pause();
      expect(controller.state.isRunning, isFalse);
      
      controller.resume();
      expect(controller.state.isRunning, isTrue);
    });

    test('TEST 4: Timer reset', () {
      controller.initialize(60);
      controller.start();
      controller.reset();
      
      expect(controller.state.isRunning, isFalse);
      expect(controller.state.remainingSeconds, 60);
      expect(controller.state.elapsedSeconds, 0);
    });
  });
}
