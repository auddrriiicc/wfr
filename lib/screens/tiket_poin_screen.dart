import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TiketPoinScreen extends StatefulWidget {
  const TiketPoinScreen({super.key});

  @override
  State<TiketPoinScreen> createState() => _TiketPoinScreenState();
}

class _TiketPoinScreenState extends State<TiketPoinScreen> {
  final TextEditingController _poinController = TextEditingController();
  final TextEditingController _voucherController = TextEditingController();

  List<dynamic> _listBankSampah = [];
  dynamic _selectedBankSampahId;
  int _jumlahPoin = 0;
  int _jumlahVoucher = 0;
  int _userPoin = 0;
  bool _isUpdating = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchBankSampah(),
      _fetchUserPoin(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserPoin() async {
    final res = await ApiService.getProfile();

    if (!mounted) return;

    if (res['success'] == true && res['data'] is Map) {
      final data = res['data'] as Map;
      final poin = data['poin'];
      setState(() {
        _userPoin = poin is int ? poin : int.tryParse('$poin') ?? 0;
      });
    }
  }

  Future<void> _fetchBankSampah() async {
    final list = await ApiService.getBankSampahList();
    if (mounted) {
      setState(() {
        _listBankSampah = list;
      });
    }
  }

  void _onPoinChanged(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    int poin = int.tryParse(value) ?? 0;
    int voucher = poin ~/ 100; // 1 voucher = 500 poin

    setState(() {
      _jumlahPoin = poin;
      _jumlahVoucher = voucher;
      _voucherController.text = voucher > 0 ? voucher.toString() : '';
    });

    _isUpdating = false;
  }

  void _onVoucherChanged(String value) {
  if (_isUpdating) return;

  _isUpdating = true;

  final int voucher =
      int.tryParse(value) ?? 0;

  // 1 voucher = 100 poin
  const int poinPerVoucher = 100;

  final int poin =
      voucher * poinPerVoucher;

  setState(() {
    _jumlahVoucher = voucher;
    _jumlahPoin = poin;

    _poinController.text =
        poin > 0 ? poin.toString() : '';
  });

  _isUpdating = false;
}

  Future<void> _submitTukarPoin() async {
    if (_jumlahPoin <= 0 || _selectedBankSampahId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi jumlah poin/voucher dan pilih bank sampah!')),
      );
      return;
    }

    if (_jumlahPoin > _userPoin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poin Anda tidak mencukupi untuk penukaran ini!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ApiService.createTiketPoin(
      _jumlahPoin,
      _jumlahVoucher,
      _selectedBankSampahId,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket Tukar Poin berhasil dibuat!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat tiket tukar poin!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('Buat Tiket Tukar Poin'),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buat Tiket Tukar Poin',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tukarkan poin Anda dengan voucher di bank sampah pilihan',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Banner Info Poin
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF109B48),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Poin Anda saat ini: $_userPoin poin',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Field Jumlah Poin
                    const Text('Jumlah Poin', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _poinController,
                      keyboardType: TextInputType.number,
                      onChanged: _onPoinChanged,
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah poin yang ingin ditukar',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Masukkan jumlah poin atau jumlah voucher di bawah', style: TextStyle(color: Colors.grey[600], fontSize: 11)),

                    // Pembatas Atau
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('atau', style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),

                    // Field Jumlah Voucher
                    const Text('Jumlah Voucher', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _voucherController,
                      keyboardType: TextInputType.number,
                      onChanged: _onVoucherChanged,
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah voucher yang ingin diperoleh',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('1 voucher = 100 poin', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(height: 16),

                    // Pilih Bank Sampah
                    const Text('Pilih Bank Sampah', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<dynamic>(
                      initialValue: _selectedBankSampahId,
                      hint: const Text('-- Pilih Bank Sampah --'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _listBankSampah.map((item) {
                        return DropdownMenuItem(
                          value: item['id'],
                          child: Text(item['nama_bank_sampah'] ?? item['nama'] ?? 'Bank Sampah'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedBankSampahId = val),
                    ),
                    const SizedBox(height: 24),

                    // Ringkasan
                    const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDECE3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Jumlah Poin:'),
                              Text('$_jumlahPoin poin', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Jumlah Voucher:'),
                              Text('$_jumlahVoucher voucher', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Aksi
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Batal', style: TextStyle(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_isSubmitting || _jumlahPoin <= 0) ? null : _submitTukarPoin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _jumlahPoin > 0 ? const Color(0xFF1B4D3E) : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Buat Tiket', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}