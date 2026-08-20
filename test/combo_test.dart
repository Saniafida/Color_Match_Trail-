import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/combo/combo.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  group('ComboController Tests', () {
    late ComboController comboController;

    setUp(() {
      comboController = ComboController();
    });

    tearDown(() {
      comboController.dispose();
    });

    test('First event -> combo 1', () {
      comboController.registerScoreEvent();
      expect(comboController.state.level, 1);
      expect(comboController.state.multiplier, 1.0);
    });

    test('Second consecutive event -> combo 2', () {
      fakeAsync((async) {
        comboController.registerScoreEvent(); // combo 1
        
        async.elapse(const Duration(seconds: 1)); // within 2 seconds
        
        comboController.registerScoreEvent(); // combo 2
        
        expect(comboController.state.level, 2);
        expect(comboController.state.multiplier, 1.25);
      });
    });

    test('Third event -> combo 3', () {
      fakeAsync((async) {
        comboController.registerScoreEvent();
        async.elapse(const Duration(seconds: 1));
        comboController.registerScoreEvent();
        async.elapse(const Duration(seconds: 1));
        comboController.registerScoreEvent();
        
        expect(comboController.state.level, 3);
        expect(comboController.state.multiplier, 1.5);
      });
    });

    test('Fifth event -> max configured tier (2.0)', () {
      fakeAsync((async) {
        for (int i = 0; i < 5; i++) {
          comboController.registerScoreEvent();
          async.elapse(const Duration(milliseconds: 500));
        }
        
        expect(comboController.state.level, 5);
        expect(comboController.state.multiplier, 2.0);
      });
    });

    test('Timeout -> reset', () {
      fakeAsync((async) {
        comboController.registerScoreEvent(); // combo 1
        expect(comboController.state.level, 1);
        
        // Wait longer than timeout
        async.elapse(const Duration(seconds: 3));
        
        // At this point, the timer inside ComboController should have called reset()
        expect(comboController.state.level, 0);
        
        // Next event starts at 1
        comboController.registerScoreEvent();
        expect(comboController.state.level, 1);
      });
    });

    test('Cascade registers continue chain', () {
      fakeAsync((async) {
        comboController.registerScoreEvent(); // combo 1
        
        async.elapse(const Duration(seconds: 1));
        
        comboController.registerCascade(1); // combo 2
        expect(comboController.state.level, 2);
      });
    });
  });
}
