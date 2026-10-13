import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/attendance.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key, required this.api, required this.user});

  final ApiClient api;
  final String user;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _location = LocationService();
  final _jam = DateFormat('HH:mm:ss');

  Position? _posisi;
  double? _jarak;
  String? _error;
  bool _sibuk = false;
  late Future<List<Attendance>> _riwayat;

  @override
  void initState() {
    super.initState();
    _riwayat = widget.api.riwayat(widget.user);
    _ambilPosisi();
  }

  Future<void> _ambilPosisi() async {
    try {
      final p = await _location.sekarang();
      if (!mounted) return;
      setState(() {
        _posisi = p;
        _jarak = _location.jarakKeKantor(p);
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  bool get _didalamRadius => _jarak != null && _jarak! <= LocationService.radiusMeter;

  Future<void> _absen(bool masuk) async {
    if (_posisi == null) {
      setState(() => _error = 'lokasi belum kebaca, coba lagi');
      return;
    }
    if (!_didalamRadius) {
      setState(() => _error = 'kamu diluar radius kantor (${_jarak!.round()} m)');
      return;
    }

    setState(() {
      _sibuk = true;
      _error = null;
    });

    try {
      if (masuk) {
        await widget.api.absenMasuk(widget.user, _posisi!);
      } else {
        await widget.api.absenKeluar(widget.user, _posisi!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(masuk ? 'absen masuk tercatat' : 'absen keluar tercatat')),
      );
      setState(() => _riwayat = widget.api.riwayat(widget.user));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jam = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _ambilPosisi,
            tooltip: 'refresh lokasi',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _ambilPosisi();
          setState(() => _riwayat = widget.api.riwayat(widget.user));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _kartuJam(jam),
            const SizedBox(height: 12),
            _kartuLokasi(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _kotakError(_error!),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sibuk || !_didalamRadius ? null : () => _absen(true),
                    icon: const Icon(Icons.login),
                    label: const Text('Masuk'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _sibuk || !_didalamRadius ? null : () => _absen(false),
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Riwayat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<Attendance>>(
              future: _riwayat,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return _kotakError(snap.error.toString());
                }
                final data = snap.data ?? [];
                if (data.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('belum ada riwayat'),
                  );
                }
                return Column(
                  children: data.map((a) => _baris(a)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuJam(DateTime jam) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _jam.format(jam),
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w300),
            ),
            Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(jam)),
          ],
        ),
      ),
    );
  }

  Widget _kartuLokasi() {
    final warna = _jarak == null
        ? Colors.grey
        : _didalamRadius
            ? Colors.green
            : Colors.red;

    return Card(
      child: ListTile(
        leading: Icon(Icons.my_location, color: warna),
        title: Text(_jarak == null ? 'mencari lokasi...' : '${_jarak!.round()} m dari kantor'),
        subtitle: Text(
          _posisi == null
              ? 'izin lokasi belum aktif'
              : '${_posisi!.latitude.toStringAsFixed(5)}, ${_posisi!.longitude.toStringAsFixed(5)}',
        ),
        trailing: _didalamRadius
            ? const Chip(label: Text('didalam'))
            : const Chip(label: Text('diluar')),
      ),
    );
  }

  Widget _kotakError(String pesan) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(pesan, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _baris(Attendance a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: a.lengkap ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            a.lengkap ? Icons.check : Icons.schedule,
            size: 18,
            color: a.lengkap ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
        title: Text(DateFormat('d MMM y').format(a.tanggal)),
        subtitle: Text('masuk ${a.masuk} · keluar ${a.keluar ?? "-"}'),
        trailing: a.terlambat
            ? const Text('telat', style: TextStyle(color: Colors.red, fontSize: 12))
            : null,
      ),
    );
  }
}
