import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/score/score.dart';
import 'package:color_match_trail/game/combo/combo.dart';
import 'package:color_match_trail/game/blast/blast_result.dart';
import 'package:color_match_trail/models/models.dart';
import 'package:color_match_trail/core/storage/storage.dart';

class MockGameStorage implements GameStorage {
  @override Future<void> init() async {}
  
  @override Future<int> getCoins() async => 0;
  @override Future<void> setCoins(int coins) async {}
  
  @override Future<int> getLives() async => 0;
  @override Future<void> setLives(int lives) async {}
  
  @override
  Future<bool> getAudioEnabled() async => true;
  @override
  Future<void> setAudioEnabled(bool enabled) async {}
  
  @override
  Future<String?> getBoosterInventoryRaw() async => null;
  @override
  Future<void> setBoosterInventoryRaw(String rawJson) async {}
}

void main() {
  group('ScoreCalculator Tests', () {
    test('Base Score', () {
      expect(ScoreCalculator.calculate(destroyedBlocks: 3, cascadeLevel: 0, comboLevel: 1).baseScore, 30);
      expect(ScoreCalculator.calculate(destroyedBlocks: 4, cascadeLevel: 0, comboLevel: 1).baseScore, 40);
      expect(ScoreCalculator.calculate(destroyedBlocks: 5, cascadeLevel: 0, comboLevel: 1).baseScore, 50);
      expect(ScoreCalculator.calculate(destroyedBlocks: 10, cascadeLevel: 0, comboLevel: 1).baseScore, 100);
    });

    test('Connection Bonus', () {
      expect(ScoreConfig.getConnectionMultiplier(3), 1.0);
      expect(ScoreConfig.getConnectionMultiplier(4), 1.25);
      expect(ScoreConfig.getConnectionMultiplier(5), 1.50);
      expect(ScoreConfig.getConnectionMultiplier(6), 1.75);
      expect(ScoreConfig.getConnectionMultiplier(7), 2.0);
      expect(ScoreConfig.getConnectionMultiplier(10), 2.0);
    });
    
    test('Cascade Bonus', () {
      expect(ScoreConfig.getCascadeMultiplier(0), 1.0);
      expect(ScoreConfig.getCascadeMultiplier(1), 1.10);
      expect(ScoreConfig.getCascadeMultiplier(2), 1.25);
      expect(ScoreConfig.getCascadeMultiplier(3), 1.50);
      expect(ScoreConfig.getCascadeMultiplier(5), 1.75);
    });

    test('Final Score Example', () {
      // 5 blocks = base 50. Connection 5 blocks = 1.5. Cascade 1 = 1.10. Combo 2 = 1.25
      // 50 * 1.5 * 1.10 * 1.25 = 103.125 => 103
      final result = ScoreCalculator.calculate(destroyedBlocks: 5, cascadeLevel: 1, comboLevel: 2);
      expect(result.finalScore, 103);
    });
  });

  group('ScoreController Tests', () {
    late ScoreController scoreController;
    late ComboController comboController;

    setUp(() {
      comboController = ComboController();
      scoreController = ScoreController(
        comboController: comboController,
      );
      scoreController.init(0);
    });

    BlastResult createBlast(int count) {
      return BlastResult(
        success: true,
        destroyedPositions: List.generate(count, (i) => Position(0, i)),
        destroyedCount: count,
      );
    }

    test('Manual match scores properly', () async {
      await scoreController.processBlast(createBlast(3)); // Base 30, Conn 1, Casc 1, Combo 1 = 30
      expect(scoreController.state.currentScore, 30);
      expect(scoreController.state.highScore, 30);
      expect(scoreController.lastScoreEvent!.pointsAdded, 30);
    });

    test('High score persists correctly', () async {
      scoreController.init(100); // Load 100
      
      await scoreController.processBlast(createBlast(5)); 
      // 5 * 10 * 1.5 * 1.0 * 1.0 = 75
      
      expect(scoreController.state.currentScore, 75);
      expect(scoreController.state.highScore, 100); // Does not overwrite
      
      await scoreController.processBlast(createBlast(4)); 
      // Current is 75. 
      // 4 blocks = 40 base. conn(4) = 1.25. cascade(0) = 1.0. combo(2) = 1.25.
      // 40 * 1.25 * 1.25 = 62.5 -> 63. 
      // 75 + 63 = 138
      
      expect(scoreController.state.currentScore, 138);
      expect(scoreController.state.highScore, 138); // Overwrote!
    });

    test('Double scoring protection', () async {
      final blast = BlastResult(
        success: true,
        destroyedPositions: [const Position(0,0), const Position(0,1), const Position(0,2)],
        destroyedCount: 3,
      );

      await scoreController.processBlast(blast);
      expect(scoreController.state.currentScore, 30);

      // Processing SAME blast object or exact same length/positions
      await scoreController.processBlast(blast);
      expect(scoreController.state.currentScore, 30); // Did not add again!
    });
    
    test('Score Format', () {
      expect(ScoreFormatter.format(125000), '125,000');
    });
  });
}
