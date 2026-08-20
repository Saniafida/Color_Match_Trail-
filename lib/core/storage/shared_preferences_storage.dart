import 'package:shared_preferences/shared_preferences.dart';
import 'storage.dart';

class SharedPreferencesGameStorage implements GameStorage {
  static const String _keyCoins = 'coins';
  static const String _keyLives = 'lives';
  static const String _keyBoosterInventory = 'booster_inventory';
  static const String _keyAudioEnabled = 'audio_enabled';

  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Players
  @override
  Future<int> getCoins() async {
    return _prefs.getInt(_keyCoins) ?? 0;
  }

  @override
  Future<void> setCoins(int coins) async {
    await _prefs.setInt(_keyCoins, coins);
  }

  @override
  Future<int> getLives() async {
    return _prefs.getInt(_keyLives) ?? 5; // Default to 5 lives
  }

  @override
  Future<void> setLives(int lives) async {
    await _prefs.setInt(_keyLives, lives);
  }

  // Boosters
  @override
  Future<String?> getBoosterInventoryRaw() async {
    return _prefs.getString(_keyBoosterInventory);
  }

  @override
  Future<void> setBoosterInventoryRaw(String rawJson) async {
    await _prefs.setString(_keyBoosterInventory, rawJson);
  }



  // Settings
  @override
  Future<bool> getAudioEnabled() async {
    return _prefs.getBool(_keyAudioEnabled) ?? true;
  }

  @override
  Future<void> setAudioEnabled(bool enabled) async {
    await _prefs.setBool(_keyAudioEnabled, enabled);
  }
}
