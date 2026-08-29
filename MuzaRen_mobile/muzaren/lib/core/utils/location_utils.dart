import 'package:geolocator/geolocator.dart';

class LocationUtils {
  /// Checks if coordinates are valid (not 0,0)
  static bool hasValidCoordinates(double lat, double lng) {
    return lat != 0.0 && lng != 0.0;
  }

  /// Calculates distance in meters between two coordinates
  static double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    // If coordinates are missing, return a dummy value that signifies "Unknown"
    if (!hasValidCoordinates(startLat, startLng) || 
        !hasValidCoordinates(endLat, endLng)) {
      return -1.0; 
    }
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Formats distance into a human-readable string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 0) return 'Nearby'; // Fallback for missing coordinates
    if (distanceInMeters == 0.0) return '0m';
    
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m away';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km away';
    }
  }
}
