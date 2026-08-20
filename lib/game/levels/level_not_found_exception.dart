class LevelNotFoundException implements Exception {
  final String message;
  final int? levelId;

  LevelNotFoundException(this.message, [this.levelId]);

  @override
  String toString() {
    if (levelId != null) {
      return "LevelNotFoundException: $message (Level ID: $levelId)";
    }
    return "LevelNotFoundException: $message";
  }
}
