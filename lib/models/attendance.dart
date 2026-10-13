class Attendance {
  Attendance({
    required this.id,
    required this.user,
    required this.tanggal,
    required this.masuk,
    this.keluar,
    required this.lat,
    required this.lng,
    required this.akurasi,
    required this.terlambat,
  });

  final int id;
  final String user;
  final DateTime tanggal;
  final String masuk;
  final String? keluar;
  final double lat;
  final double lng;
  final double akurasi;
  final bool terlambat;

  bool get lengkap => keluar != null;

  factory Attendance.fromJson(Map<String, dynamic> j) {
    return Attendance(
      id: j['id'] as int,
      user: j['username'] as String,
      tanggal: DateTime.parse(j['tanggal'] as String),
      masuk: j['masuk'] as String,
      keluar: j['keluar'] as String?,
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      akurasi: (j['akurasi'] as num?)?.toDouble() ?? 0,
      terlambat: j['terlambat'] as bool? ?? false,
    );
  }

  Duration? get durasi {
    if (keluar == null) return null;
    final a = _keDetik(masuk);
    final b = _keDetik(keluar!);
    if (a == null || b == null) return null;
    return Duration(seconds: b - a);
  }

  int? _keDetik(String jam) {
    final bagian = jam.split(':');
    if (bagian.length < 2) return null;
    final h = int.tryParse(bagian[0]);
    final m = int.tryParse(bagian[1]);
    if (h == null || m == null) return null;
    return h * 3600 + m * 60;
  }
}
