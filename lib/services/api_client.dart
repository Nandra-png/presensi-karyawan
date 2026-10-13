import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/attendance.dart';

class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  final String baseUrl;
  String? token;

  Map<String, String> get _header => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<String> login(String user, String sandi) async {
    final r = await http.post(
      Uri.parse('$baseUrl/masuk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': user, 'password': sandi}),
    );
    if (r.statusCode != 200) {
      throw Exception('login gagal (${r.statusCode})');
    }
    final d = jsonDecode(r.body) as Map<String, dynamic>;
    token = d['token'] as String;
    return token!;
  }

  Future<void> absenMasuk(String user, Position pos) async {
    final r = await http.post(
      Uri.parse('$baseUrl/absen/masuk'),
      headers: _header,
      body: jsonEncode({
        'username': user,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'akurasi': pos.accuracy,
      }),
    );
    _cek(r);
  }

  Future<void> absenKeluar(String user, Position pos) async {
    final r = await http.post(
      Uri.parse('$baseUrl/absen/keluar'),
      headers: _header,
      body: jsonEncode({
        'username': user,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'akurasi': pos.accuracy,
      }),
    );
    _cek(r);
  }

  Future<List<Attendance>> riwayat(String user) async {
    final r = await http.get(
      Uri.parse('$baseUrl/absen/riwayat/$user'),
      headers: _header,
    );
    _cek(r);
    final d = jsonDecode(r.body) as Map<String, dynamic>;
    return (d['data'] as List)
        .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _cek(http.Response r) {
    if (r.statusCode >= 400) {
      String pesan = 'error ${r.statusCode}';
      try {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        if (d['message'] != null) pesan = d['message'] as String;
      } catch (_) {}
      throw Exception(pesan);
    }
  }
}
