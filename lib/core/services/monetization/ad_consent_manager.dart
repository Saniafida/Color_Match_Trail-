enum AdConsentStatus {
  unknown,
  required,
  granted,
  denied,
  notRequired,
}

abstract class AdConsentManager {
  Future<AdConsentStatus> checkConsent();
  Future<AdConsentStatus> requestConsent();
}

/// Stub implementation that assumes consent is granted or not required.
class StubAdConsentManager implements AdConsentManager {
  AdConsentStatus _status = AdConsentStatus.notRequired;

  @override
  Future<AdConsentStatus> checkConsent() async {
    // Stub: simulate checking consent
    await Future.delayed(const Duration(milliseconds: 100));
    return _status;
  }

  @override
  Future<AdConsentStatus> requestConsent() async {
    // Stub: simulate requesting consent
    await Future.delayed(const Duration(milliseconds: 500));
    _status = AdConsentStatus.granted;
    return _status;
  }
}
