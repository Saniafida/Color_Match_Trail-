import 'package:flutter/foundation.dart';

/// Handles data version compatibility checks and provides migration hooks.
///
/// Currently a pass-through (v1 to v1 = no migration needed).
class GameDataMigrationManager {
  static const int currentDataVersion = 1;

  /// Checks a data file's reported version and returns whether migration is needed.
  MigrationCheckResult checkVersion(int? reportedVersion, String dataSource) {
    final version = reportedVersion ?? 1;

    if (version == currentDataVersion) {
      return MigrationCheckResult(
        dataSource: dataSource,
        fromVersion: version,
        toVersion: currentDataVersion,
        migrationRequired: false,
      );
    }

    if (version > currentDataVersion) {
      return MigrationCheckResult(
        dataSource: dataSource,
        fromVersion: version,
        toVersion: currentDataVersion,
        migrationRequired: false,
        warning: 'Data file "$dataSource" version ($version) is newer than the app supports ($currentDataVersion). '
            'Consider updating the app.',
      );
    }

    // version < currentDataVersion — migration needed
    return MigrationCheckResult(
      dataSource: dataSource,
      fromVersion: version,
      toVersion: currentDataVersion,
      migrationRequired: true,
    );
  }

  /// Applies all registered migration steps from [fromVersion] to [currentDataVersion].
  ///
  /// Returns the migrated JSON map.
  Map<String, dynamic> migrate(Map<String, dynamic> data, int fromVersion) {
    var current = Map<String, dynamic>.from(data);

    // Migration steps: add entries below as new versions are introduced.
    // Example:
    // if (fromVersion < 2) current = _migrateV1toV2(current);
    // if (fromVersion < 3) current = _migrateV2toV3(current);

    if (kDebugMode) {
      debugPrint('[GameDataMigration] Migrated data from v$fromVersion to v$currentDataVersion');
    }

    return current;
  }
}

class MigrationCheckResult {
  final String dataSource;
  final int fromVersion;
  final int toVersion;
  final bool migrationRequired;
  final String? warning;

  const MigrationCheckResult({
    required this.dataSource,
    required this.fromVersion,
    required this.toVersion,
    required this.migrationRequired,
    this.warning,
  });
}
