import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminScanQrScreen extends StatefulWidget {
  const AdminScanQrScreen({super.key});

  @override
  State<AdminScanQrScreen> createState() => _AdminScanQrScreenState();
}

class _AdminScanQrScreenState extends State<AdminScanQrScreen> {
  static const Color primaryGreen = Color(0xFF135232);
  static const Color pageBackground = Color(0xFFF4F7F5);
  static const Color softGreen = Color(0xFFE8F0EC);

  final TextEditingController _kodeController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _kodeController.dispose();
    super.dispose();
  }

  Future<void> _checkCode() async {
    final kode = _kodeController.text.trim();
    if (kode.isEmpty) {
      setState(() => _error = 'Masukkan kode QR/tiket terlebih dahulu.');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    final response = await ApiService.scanAdminQr(kode);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response['success'] == true && response['data'] is Map) {
        _result = Map<String, dynamic>.from(response['data']);
      } else {
        _error = response['message']?.toString() ?? 'Tiket tidak ditemukan.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Scan QR'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Verifikasi Tiket',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Masukkan kode tiket yang tercetak pada QR untuk mencari data setoran masyarakat',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Kode QR / Kode Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _kodeController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _checkCode(),
              decoration: InputDecoration(
                hintText: 'Contoh: TKT-ABC12345',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  onPressed: _isLoading ? null : _checkCode,
                  icon: const Icon(Icons.search),
                  color: primaryGreen,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkCode,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner),
                label: Text(_isLoading ? 'Memeriksa...' : 'Periksa Kode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: primaryGreen),
                        SizedBox(width: 8),
                        Text('Tiket ditemukan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _row('Kode', _result!['kode_tiket']),
                    _row('Masyarakat', _result!['nama_lengkap']),
                    _row('Berat estimasi', '${_result!['berat'] ?? 0} Kg'),
                    _row('Berat aktual', '${_result!['berat_actual'] ?? '-'} Kg'),
                    _row('Poin final', '${_result!['poin_final'] ?? '-'} poin'),
                    _row('Status', _result!['status']),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Catatan: halaman ini menggunakan kode tiket sebagai sumber pencarian QR. Kamera QR dapat ditambahkan tanpa mengubah endpoint backend yang sudah dibuat.',
                style: TextStyle(fontSize: 11, color: primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Flexible(
            child: Text(
              value?.toString() ?? '-',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
