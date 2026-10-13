import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double kantorLat = -6.2088;
  static const double kantorLng = 106.8456;
  static const double radiusMeter = 150;

  Future<Position> sekarang() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('gps mati, nyalain dulu');
    }

    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    if (izin == LocationPermission.denied) {
      throw Exception('izin lokasi ditolak');
    }
    if (izin == LocationPermission.deniedForever) {
      throw Exception('izin lokasi diblokir permanen, buka setelan');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  double jarakKeKantor(Position p) {
    return jarakMeter(p.latitude, p.longitude, kantorLat, kantorLng);
  }

  double jarakMeter(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double deg) => deg * math.pi / 180;
}
