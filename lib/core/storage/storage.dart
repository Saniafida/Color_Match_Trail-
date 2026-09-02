// Storage Foundation
// 
// Abstract interface for local persistence of player data.
// Implementation to be added in future modules.

export 'shared_preferences_storage.dart';

abstract class GameStorage {
  Future<void> init();
  
  // Players
  Future<int> getCoins();
  Future<void> setCoins(int coins);
  
  Future<int> getLives();
  Future<void> setLives(int lives);

  Future<int> getGems();
  Future<void> setGems(int gems);
  
  // Boosters
  Future<String?> getBoosterInventoryRaw();
  Future<void> setBoosterInventoryRaw(String rawJson);


  
  // Settings
  Future<bool> getAudioEnabled();
  Future<void> setAudioEnabled(bool enabled);
}
