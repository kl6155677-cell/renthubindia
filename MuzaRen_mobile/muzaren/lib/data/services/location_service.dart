import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';

class LocationResult {
  final String city;
  final String country;
  final String countryCode;
  final double lat;
  final double lng;
  final String source; // 'gps' | 'ip' | 'saved' | 'default'

  const LocationResult({
    required this.city,
    required this.country,
    required this.countryCode,
    required this.lat,
    required this.lng,
    required this.source,
  });
}

class LocationService {

  /// Main entry point — tries GPS first, falls back to IP
  static Future<LocationResult?> detectLocation() async {
    // Try GPS first
    final gpsResult = await _detectFromGPS();
    if (gpsResult != null) return gpsResult;

    // GPS failed — try IP geolocation
    final ipResult = await _detectFromIP();
    return ipResult;
  }

  /// Detect location from device GPS
  static Future<LocationResult?> _detectFromGPS() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Get position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // Use high accuracy for precise location
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Reverse geocode to get city and country
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (_) {}

      String? city;
      String? country;
      String? countryCode;

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final pLocality = placemark.locality;
        final pSubAdmin = placemark.subAdministrativeArea;
        final pAdmin = placemark.administrativeArea;
        
        if (pLocality != null && pLocality.trim().isNotEmpty) {
          city = pLocality;
        } else if (pSubAdmin != null && pSubAdmin.trim().isNotEmpty) {
          city = pSubAdmin;
        } else if (pAdmin != null && pAdmin.trim().isNotEmpty) {
          city = pAdmin;
        }

        final pCountry = placemark.country;
        if (pCountry != null && pCountry.trim().isNotEmpty) {
          country = pCountry;
        }
        
        final pCountryCode = placemark.isoCountryCode;
        if (pCountryCode != null && pCountryCode.trim().isNotEmpty) {
          countryCode = pCountryCode;
        }
      }

      // Fallback if native geocoding missed the country (e.g., disputed territory) or failed entirely
      if (country == null || countryCode == null || city == null) {
        final fallback = await _fallbackReverseGeocode(position.latitude, position.longitude, 'gps');
        if (fallback != null) {
          city ??= fallback.city != 'New York City' ? fallback.city : null;
          country ??= fallback.country != 'United States' ? fallback.country : null;
          countryCode ??= fallback.countryCode != 'US' ? fallback.countryCode : null;
        }
      }

      return LocationResult(
        city:        city ?? 'New York City',
        country:     country ?? 'United States',
        countryCode: (countryCode ?? 'US').toUpperCase(),
        lat:         position.latitude,
        lng:         position.longitude,
        source:      'gps',
      );
    } catch (e) {
      // GPS detection failed — return null to trigger IP fallback
      return null;
    }
  }

  /// Detect location from IP address (fallback when GPS unavailable)
  static Future<LocationResult?> _detectFromIP() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      // Primary IP geolocation service
      final response = await dio.get('http://ip-api.com/json');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final rCity = response.data['city'];
        final city = (rCity == null || rCity.toString().trim().isEmpty) ? null : rCity.toString();
        
        final rCountry = response.data['country'];
        final country = (rCountry == null || rCountry.toString().trim().isEmpty) ? null : rCountry.toString();
        
        final rCountryCode = response.data['countryCode'];
        final countryCode = (rCountryCode == null || rCountryCode.toString().trim().isEmpty) ? null : rCountryCode.toString();
        final lat         = (response.data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng         = (response.data['lon'] as num?)?.toDouble() ?? 0.0;

        return LocationResult(
          city:        city ?? 'New York City',
          country:     country ?? 'United States',
          countryCode: (countryCode ?? 'US').toUpperCase(),
          lat:         lat,
          lng:         lng,
          source:      'ip',
        );
      }

      // Try backup IP service if primary fails
      return await _detectFromIPBackup(dio);
    } catch (e) {
      return null;
    }
  }

  /// Backup IP geolocation service
  static Future<LocationResult?> _detectFromIPBackup(Dio dio) async {
    try {
      final response = await dio.get('https://ipapi.co/json/');

      if (response.statusCode == 200) {
        final rCity = response.data['city'];
        final city = (rCity == null || rCity.toString().trim().isEmpty) ? null : rCity.toString();
        
        final rCountry = response.data['country_name'];
        final country = (rCountry == null || rCountry.toString().trim().isEmpty) ? null : rCountry.toString();
        
        final rCountryCode = response.data['country_code'];
        final countryCode = (rCountryCode == null || rCountryCode.toString().trim().isEmpty) ? null : rCountryCode.toString();
        final lat         = (response.data['latitude']  as num?)?.toDouble() ?? 0.0;
        final lng         = (response.data['longitude'] as num?)?.toDouble() ?? 0.0;

        return LocationResult(
          city:        city ?? 'New York City',
          country:     country ?? 'United States',
          countryCode: (countryCode ?? 'US').toUpperCase(),
          lat:         lat,
          lng:         lng,
          source:      'ip',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fallback reverse geocoding via BigDataCloud API for missing native fields
  static Future<LocationResult?> _fallbackReverseGeocode(double lat, double lng, String source) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get('https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en');
      if (response.statusCode == 200) {
        final rCity = response.data['city'];
        final locality = response.data['locality'];
        final principalSub = response.data['principalSubdivision'];
        
        String? city;
        if (rCity != null && rCity.toString().trim().isNotEmpty) {
          city = rCity.toString();
        } else if (locality != null && locality.toString().trim().isNotEmpty) {
          city = locality.toString();
        } else if (principalSub != null && principalSub.toString().trim().isNotEmpty) {
          city = principalSub.toString();
        }

        final rCountry = response.data['countryName'];
        final country = (rCountry != null && rCountry.toString().trim().isNotEmpty) ? rCountry.toString() : null;
        
        final rCountryCode = response.data['countryCode'];
        final countryCode = (rCountryCode != null && rCountryCode.toString().trim().isNotEmpty) ? rCountryCode.toString() : null;

        if (city == null && country == null) return null;

        return LocationResult(
          city:        city ?? 'New York City',
          country:     country ?? 'United States',
          countryCode: (countryCode ?? 'US').toUpperCase(),
          lat:         lat,
          lng:         lng,
          source:      source,
        );
      }
    } catch (_) {}
    return null;
  }
}
