# presensi-karyawan

Flutter app for employee attendance. GPS-gated check-in, attendance history.

## How it works

The employee must be within 150 m of the office coordinates to check in. The distance is Haversine, computed on device. If they're outside, the buttons stay disabled and the app tells them how far off they are.

## Flow

```
login          NIP + password, gets a JWT
check-in       current time, live GPS distance to office
history        past records, late flagged
```

The clock card shows live local time. The location card turns green when inside the radius, red when outside. Pull to refresh re-reads GPS and reloads history.

## Config

Office coordinates and radius are in `lib/services/location_service.dart`:

```dart
static const double kantorLat = -6.2088;
static const double kantorLng = 106.8456;
static const double radiusMeter = 150;
```

API base URL is set in `lib/main.dart`, defaults to `http://10.0.2.2:8080` (Android emulator loopback).

## Setup

```
flutter pub get
flutter run
```

## Permissions

Android needs location and in newer versions a background location entry. The app requests `ACCESS_FINE_LOCATION` at runtime and shows a clear message if it's denied permanently, with a nudge to open settings.

If GPS is off entirely, check-in fails with "gps mati, nyalain dulu" rather than hanging.

## Distance

```dart
double jarakMeter(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat/2) * sin(dLat/2) + cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng/2) * sin(dLng/2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}
```

## What's missing

- coordinates hardcoded, not fetched from the backend
- no mock-location detection
- no offline queue, check-ins need network
- no admin view
- no photo capture at check-in
