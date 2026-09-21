import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await handlePermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if miner is within valid mine perimeter radius (in meters)
  static bool isWithinZone({
    required double userLat,
    required double userLng,
    required double zoneLat,
    required double zoneLng,
    double radiusMeters = 500,
  }) {
    final distance = Geolocator.distanceBetween(userLat, userLng, zoneLat, zoneLng);
    return distance <= radiusMeters;
  }
}
