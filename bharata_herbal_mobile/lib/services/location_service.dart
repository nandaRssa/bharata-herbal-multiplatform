import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String street;
  final String city;
  final String province;
  final String postalCode;
  final String fullAddress;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.street,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.fullAddress,
  });
}

/// Service GPS + Reverse Geocoding untuk auto-fill alamat pengiriman
class LocationService {
  /// Minta izin lokasi dan dapatkan koordinat + nama alamat
  Future<LocationResult?> getCurrentLocation() async {
    // 1. Cek apakah location service aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS tidak aktif. Aktifkan lokasi di pengaturan HP.');
    }

    // 2. Cek dan minta permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi diblokir permanen. Aktifkan melalui Pengaturan Aplikasi.',
      );
    }

    // 3. Dapatkan posisi
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    // 4. Reverse Geocoding
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      throw Exception('Tidak dapat menentukan alamat dari lokasi ini.');
    }

    final place = placemarks.first;

    // Susun komponen alamat
    final street = [
      place.street ?? '',
      place.subLocality ?? '',
    ].where((s) => s.isNotEmpty).join(', ');

    final city = place.subAdministrativeArea ??
        place.locality ??
        place.administrativeArea ??
        '';
    final province = place.administrativeArea ?? '';
    final postalCode = place.postalCode ?? '';
    final fullAddress = [
      street,
      city,
      province,
      postalCode,
      place.country ?? '',
    ].where((s) => s.isNotEmpty).join(', ');

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      street: street,
      city: city,
      province: province,
      postalCode: postalCode,
      fullAddress: fullAddress,
    );
  }
}
