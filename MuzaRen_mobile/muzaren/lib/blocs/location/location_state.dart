abstract class LocationState {
  const LocationState();
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationDetecting extends LocationState {
  const LocationDetecting();
}

class LocationDetected extends LocationState {
  final String city;
  final String country;
  final String countryCode;
  final String currency;       // e.g. 'SGD'
  final String currencySymbol; // e.g. 'S$'
  final double latitude;
  final double longitude;

  const LocationDetected({
    required this.city,
    required this.country,
    required this.countryCode,
    required this.currency,
    required this.currencySymbol,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPermissionDenied extends LocationState {
  const LocationPermissionDenied();
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);
}

class LocationNotServiceable extends LocationState {
  final String city;
  const LocationNotServiceable(this.city);
}
