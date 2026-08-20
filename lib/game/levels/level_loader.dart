import 'dart:convert';
import '../../models/level.dart';
import 'level_validator.dart';
import 'level_validation_result.dart';

class LevelLoader {
  final LevelValidator _validator;

  LevelLoader({LevelValidator? validator}) : _validator = validator ?? LevelValidator();

  LevelDefinition loadFromJsonString(String jsonString) {
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    return _parseAndValidate(jsonData);
  }
  
  List<LevelDefinition> loadMultipleFromJsonString(String jsonString) {
     final List<dynamic> jsonList = jsonDecode(jsonString);
     return jsonList.map((data) => _parseAndValidate(data as Map<String, dynamic>)).toList();
  }

  LevelDefinition _parseAndValidate(Map<String, dynamic> jsonData) {
    final level = LevelDefinition.fromJson(jsonData);
    final LevelValidationResult result = _validator.validate(level);

    if (!result.isValid) {
      throw StateError('Invalid level data for level ID ${level.id}: ${result.errors.join(", ")}');
    }

    return level;
  }
}
