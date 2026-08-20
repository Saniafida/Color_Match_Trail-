import 'dart:ui';

class AppLocale {
  final String languageCode;
  final String? countryCode;
  final String displayName;
  final String nativeName;
  final TextDirection textDirection;

  const AppLocale({
    required this.languageCode,
    this.countryCode,
    required this.displayName,
    required this.nativeName,
    this.textDirection = TextDirection.ltr,
  });

  Locale get flutterLocale => Locale(languageCode, countryCode);
}
