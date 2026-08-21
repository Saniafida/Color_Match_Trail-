import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/game/balance/game_balance_manager.dart';
import 'package:color_match_trail/game/balance/difficulty_tier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameBalanceManager balanceManager;

  setUp(() async {
    balanceManager = GameBalanceManager();
    await balanceManager.initialize();
  });

  group('Module 55 Game Balance Tests', () {
    test('1. Balance manager initializes and loads configuration', () {
      expect(balanceManager.isLoaded, isTrue);
      expect(balanceManager.config.baseScorePerBlock, equals(10));
      expect(balanceManager.config.minMatchLength, equals(3));
    });

    test('2. Difficulty definitions are properly populated', () {
      final easy = balanceManager.getDifficultyDefinition('easy');
      final expert = balanceManager.getDifficultyDefinition('expert');

      expect(easy, isNotNull);
      expect(easy!.tier, equals('easy'));
      expect(easy.minColors, equals(3));

      expect(expert, isNotNull);
      expect(expert!.tier, equals('expert'));
      expect(expert.minColors, greaterThanOrEqualTo(5));
    });

    test('3. Star thresholds and booster configs are valid', () {
      expect(balanceManager.config.star1ScorePercent, equals(50));
      expect(balanceManager.config.star2ScorePercent, equals(75));
      expect(balanceManager.config.star3ScorePercent, equals(100));

      expect(balanceManager.config.hammerCoinCost, greaterThan(0));
      expect(balanceManager.config.shuffleCoinCost, greaterThan(0));
      expect(balanceManager.config.extraMovesGranted, equals(5));
    });

    test('4. Difficulty testing presets apply in development mode', () {
      balanceManager.applyDifficultyPreset(DifficultyTier.easy);
      expect(balanceManager.config.baseScorePerBlock, equals(20));

      balanceManager.applyDifficultyPreset(DifficultyTier.hard);
      expect(balanceManager.config.specialBlockSpawnChance, equals(0.02));
    });
  });
}
