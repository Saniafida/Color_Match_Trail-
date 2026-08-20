enum GameDataStatus {
  /// Data has not been requested yet
  notLoaded,

  /// Data is currently being loaded
  loading,

  /// Data loaded and validated successfully
  loaded,

  /// Load or validation failed (game may continue with safe fallbacks)
  failed,
}
