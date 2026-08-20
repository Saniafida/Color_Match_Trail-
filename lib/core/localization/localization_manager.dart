import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../game/settings/settings_manager.dart';
import 'app_locale.dart';
import 'localization_config.dart';
import 'translation_loader.dart';

class LocalizationManager extends ChangeNotifier {
  final SettingsManager settingsManager;
  final TranslationLoader _loader = TranslationLoader();

  AppLocale _currentLocale = LocalizationConfig.fallbackLocale;
  Map<String, dynamic> _translations = {};
  Map<String, dynamic> _fallbackTranslations = {};
  bool _initialized = false;

  LocalizationManager({required this.settingsManager}) {
    settingsManager.addListener(_onSettingsChanged);
  }

  AppLocale get currentLocale => _currentLocale;
  TextDirection get textDirection => _currentLocale.textDirection;
  
  Future<void> initialize() async {
    if (_initialized) return;

    // Load fallback English once
    _fallbackTranslations = await _loader.loadTranslations(LocalizationConfig.fallbackLocale.languageCode);
    
    await _updateLocaleFromSettings();
    _initialized = true;
  }

  Future<void> _onSettingsChanged() async {
    if (!_initialized) return;
    await _updateLocaleFromSettings();
  }

  Future<void> _updateLocaleFromSettings() async {
    final languagePref = settingsManager.state.language;
    String targetLangCode = languagePref;

    if (languagePref == 'system') {
      final systemLocale = PlatformDispatcher.instance.locale;
      targetLangCode = systemLocale.languageCode;
    }

    // Check if target is supported
    var newLocale = LocalizationConfig.supportedLocales.firstWhere(
      (l) => l.languageCode == targetLangCode,
      orElse: () => LocalizationConfig.fallbackLocale,
    );

    if (_currentLocale.languageCode != newLocale.languageCode || _translations.isEmpty) {
      _currentLocale = newLocale;
      _translations = await _loader.loadTranslations(_currentLocale.languageCode);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    await settingsManager.setLanguage(languageCode);
  }

  /// Translates a key, returning the translation or falling back to English.
  String translate(String key, [Map<String, dynamic>? args]) {
    String? value = _translations[key] ?? _fallbackTranslations[key];

    if (value == null) {
      // Return key if translation is missing everywhere
      return key;
    }

    if (args != null) {
      args.forEach((argKey, argValue) {
        value = value!.replaceAll('{$argKey}', argValue.toString());
      });
    }

    return value!;
  }

  @override
  void dispose() {
    settingsManager.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
