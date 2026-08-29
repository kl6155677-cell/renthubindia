abstract class LocationEvent {
  const LocationEvent();
}

/// Triggered automatically after AuthAuthenticated
/// Detects location from GPS or IP fallback
class DetectLocation extends LocationEvent {
  final bool force;
  const DetectLocation({this.force = false});
}

/// Triggered when user manually changes city in Home Screen
/// Auto-derives currency from new country (unless manually overridden)
class ManualLocationChanged extends LocationEvent {
  final String city;
  final String country;
  final String countryCode;

  const ManualLocationChanged({
    required this.city,
    required this.country,
    required this.countryCode,
  });
}

/// Triggered when user manually selects a currency in Settings
/// Sets the 'currency_manually_set' flag in SharedPreferences
class ManualCurrencyOverride extends LocationEvent {
  final String currencyCode;

  const ManualCurrencyOverride({required this.currencyCode});
}

/// Triggered when user taps "Reset to automatic" in Settings
/// Clears the manual override and re-derives from country
class ResetCurrencyToAuto extends LocationEvent {
  const ResetCurrencyToAuto();
}
