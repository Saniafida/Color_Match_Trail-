import 'dart:convert';
import 'storage.dart';
import 'game_save_manager.dart';

class GameSaveManagerStorage implements GameStorage {
  final GameSaveManager saveManager;

  GameSaveManagerStorage({required this.saveManager});

  @override
  Future<void> init() async {
    // Initialized externally via GameSaveManager
  }

  @override
  Future<int> getCoins() async {
    return saveManager.playerData.coins;
  }

  @override
  Future<void> setCoins(int coins) async {
    saveManager.updateCoins(coins);
  }

  @override
  Future<int> getGems() async {
    return saveManager.playerData.gems;
  }

  @override
  Future<void> setGems(int gems) async {
    saveManager.updateGems(gems);
  }

  @override
  Future<int> getLives() async {
    // Lives are unused, returning mock
    return 5; 
  }

  @override
  Future<void> setLives(int lives) async {
    // Unused
  }

  @override
  Future<String?> getBoosterInventoryRaw() async {
    final inventory = saveManager.playerData.boosterInventory;
    if (inventory.isEmpty) return null;
    return jsonEncode(inventory);
  }

  @override
  Future<void> setBoosterInventoryRaw(String rawJson) async {
    saveManager.updateBoosterInventory(jsonDecode(rawJson));
  }

  @override
  Future<bool> getAudioEnabled() async {
    return true; // Unused, migrated to SettingsManager
  }

  @override
  Future<void> setAudioEnabled(bool enabled) async {
    // Unused
  }
}
