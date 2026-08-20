import 'settings_state.dart';
import '../../core/storage/game_save_manager.dart';

class SettingsStorage {
  final GameSaveManager saveManager;

  SettingsStorage({required this.saveManager});

  Future<void> saveSettings(SettingsState state) async {
    saveManager.updateSettings(state.toJson());
  }

  Future<SettingsState?> loadSettings() async {
    final map = saveManager.playerData.settings;
    if (map.isNotEmpty) {
      try {
        return SettingsState.fromJson(map);
      } catch (e) {
        return null; // Fallback handled by manager
      }
    }
    return null;
  }
}
