import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationLoader {
  static const String _basePath = 'assets/locales/';

  Future<Map<String, dynamic>> loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath$languageCode.json');
      return _flattenMap(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (e) {
      // If language file is missing, return empty map (fallback will handle it)
      return {};
    }
  }

  /// Flattens a nested map into a single-level map with dot-separated keys.
  /// Example: {"home": {"play": "Play"}} -> {"home.play": "Play"}
  Map<String, dynamic> _flattenMap(Map<String, dynamic> map, [String prefix = '']) {
    final Map<String, dynamic> result = {};
    map.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        result.addAll(_flattenMap(value, newKey));
      } else {
        result[newKey] = value.toString();
      }
    });
    return result;
  }
}
