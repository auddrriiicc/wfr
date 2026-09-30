import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TiketSampahScreen extends StatefulWidget {
  const TiketSampahScreen({super.key});

  @override
  State<TiketSampahScreen> createState() => _TiketSampahScreenState();
}

class _TiketSampahScreenState extends State<TiketSampahScreen> {
  final TextEditingController _beratController = TextEditingController();

  List<dynamic> _listBankSampah = [];
  dynamic _selectedBankSampahId;
  double _beratEstimasi = 0.0;
  int _poinEstimasi = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchBankSampah();
  }

  Future<void> _fetchBankSampah() async {
    final list = await ApiService.getBankSampahList();
    if (mounted) {
      setState(() {
        _listBankSampah = list;
        _isLoading = false;
      });
    }
  }

  void _onBeratChanged(String value) {
    setState(() {
      // Menggunakan double.tryParse agar mendukung angka desimal (misal 1.5)
      _beratEstimasi = double.tryParse(value) ?? 0.0;
      _poinEstimasi = (_beratEstimasi * 1000).toInt(); // Estimasi 1 Kg = 1000 poin
    });
  }

  Future<void> _submitTiket() async {
    if (_beratEstimasi <= 0 || _selectedBankSampahId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan berat dan pilih bank sampah!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Mengirim berat dan ID bank sampah ke API
    bool success = await ApiService.createTiketSampah(_beratEstimasi, _selectedBankSampahId);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket Setor Sampah berhasil dibuat!')),
      );
      Navigator.pop(context, true); // Kembali ke halaman sebelumnya dan refresh
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat tiket setor sampah! Check log console.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('Buat Tiket Setor Sampah'),
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
                      'Buat Tiket Setor Sampah',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Isi form di bawah untuk membuat tiket setor sampah baru',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Field Berat
                    const Text('Berat Estimasi (Kg)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _beratController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _onBeratChanged,
                      decoration: InputDecoration(
                        hintText: 'Masukkan berat sampah dalam Kg (contoh: 2.5)',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimasi berat akan diproses oleh petugas bank sampah',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Bank Sampah
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
                              const Text('Berat Sampah:'),
                              Text('$_beratEstimasi Kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Poin Estimasi:'),
                              Text('$_poinEstimasi poin', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            onPressed: _isSubmitting ? null : _submitTiket,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4D3E),
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