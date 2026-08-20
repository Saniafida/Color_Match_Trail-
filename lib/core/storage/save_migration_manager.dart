import 'player_save_data.dart';
import 'save_version.dart';

class SaveMigrationManager {
  static PlayerSaveData migrate(PlayerSaveData oldData) {
    if (oldData.saveVersion == currentSaveVersion) {
      return oldData;
    }

    PlayerSaveData migratedData = oldData;

    // Example migration chain:
    // if (migratedData.saveVersion == 1) {
    //   migratedData = _migrateV1ToV2(migratedData);
    // }

    // Final stamp
    return migratedData.copyWith(saveVersion: currentSaveVersion);
  }
}
