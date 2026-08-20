import 'dart:ui';
import 'app_locale.dart';

class LocalizationConfig {
  static const AppLocale fallbackLocale = AppLocale(
    languageCode: 'en',
    displayName: 'English',
    nativeName: 'English',
  );

  static const List<AppLocale> supportedLocales = [
    fallbackLocale,
    AppLocale(
      languageCode: 'es',
      displayName: 'Spanish',
      nativeName: 'Español',
    ),
    AppLocale(
      languageCode: 'fr',
      displayName: 'French',
      nativeName: 'Français',
    ),
    AppLocale(
      languageCode: 'de',
      displayName: 'German',
      nativeName: 'Deutsch',
    ),
    AppLocale(
      languageCode: 'pt',
      displayName: 'Portuguese',
      nativeName: 'Português',
    ),
    AppLocale(
      languageCode: 'it',
      displayName: 'Italian',
      nativeName: 'Italiano',
    ),
    AppLocale(
      languageCode: 'tr',
      displayName: 'Turkish',
      nativeName: 'Türkçe',
    ),
    AppLocale(
      languageCode: 'id',
      displayName: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
    ),
    AppLocale(
      languageCode: 'ar',
      displayName: 'Arabic',
      nativeName: 'العربية',
      textDirection: TextDirection.rtl,
    ),
  ];

  static List<String> get supportedLanguageCodes =>
      supportedLocales.map((l) => l.languageCode).toList();
}
