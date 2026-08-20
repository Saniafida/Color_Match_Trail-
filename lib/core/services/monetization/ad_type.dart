enum AdType {
  rewarded,
  interstitial,
  banner,
  appOpen,
}

extension AdTypeExtension on AdType {
  String get displayName {
    switch (this) {
      case AdType.rewarded:
        return 'Rewarded Video';
      case AdType.interstitial:
        return 'Interstitial';
      case AdType.banner:
        return 'Banner';
      case AdType.appOpen:
        return 'App Open';
    }
  }
}
