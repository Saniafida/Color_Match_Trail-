import 'package:flutter/services.dart';
import '../../models/level.dart';
import 'level_loader.dart';
import 'level_not_found_exception.dart';
import 'adventure_level_generator.dart';

class LevelRepository {
  final String _assetPath = 'assets/levels/levels.json';
  final LevelLoader _loader;
  final Map<int, LevelDefinition> _cache = {};

  LevelRepository({LevelLoader? loader}) : _loader = loader ?? LevelLoader();

  Future<void> preloadAll() async {
    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      final levels = _loader.loadMultipleFromJsonString(jsonString);
      
      for (var level in levels) {
        _cache[level.id] = level;
      }
    } catch (_) {
      // Non-fatal if asset load is missing or in tests; generated levels will supply data
    }
  }

  Future<LevelDefinition> getLevel(int levelId) async {
    if (_cache.containsKey(levelId)) {
      return _cache[levelId]!;
    }

    if (_cache.isEmpty) {
      try {
        await preloadAll();
      } catch (_) {}
      if (_cache.containsKey(levelId)) {
        return _cache[levelId]!;
      }
    }

    // Automatically generate procedural level for levels 1 to 147+
    if (levelId >= 1) {
      final generated = AdventureLevelGenerator.generateLevel(levelId);
      _cache[levelId] = generated;
      return generated;
    }

    throw LevelNotFoundException('Level $levelId not found.', levelId);
  }

  void clearCache() {
    _cache.clear();
  }

  List<LevelDefinition> getAllLevels() {
    final levels = _cache.values.toList();
    levels.sort((a, b) => a.id.compareTo(b.id));
    return levels;
  }
}
