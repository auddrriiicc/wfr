import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SetorPage extends StatefulWidget {
  const SetorPage({super.key});

  @override
  State<SetorPage> createState() => _SetorPageState();
}

class _SetorPageState extends State<SetorPage> {
  List<dynamic> _bankSampahList = [];
  String? _selectedBankSampahId; // Gunakan String? agar konsisten
  final _beratController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBankSampah();
  }

  void _loadBankSampah() async {
    try {
      final data = await ApiService.getBankSampahList();
      
      // CETAK UNTUK CEK STRUKTUR DATA DI DEBUG CONSOLE
      print('>>> DATA BANK SAMPAH DARI API: $data');

      if (mounted) {
        setState(() {
          _bankSampahList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('>>> ERROR LOAD BANK SAMPAH: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitData() async {
    final beratGram = int.tryParse(_beratController.text);

    if (_selectedBankSampahId == null || beratGram == null || beratGram <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan berat dan pilih bank sampah')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ApiService.createTiketSampah(
      beratGram,
      _selectedBankSampahId,
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket setor berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat tiket setor!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setor Sampah'),
        backgroundColor: const Color(0xFF135232),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _bankSampahList.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Data Bank Sampah kosong / gagal diambil dari server.',
                                  style: TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Bank Sampah',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedBankSampahId,
                          items: _bankSampahList.map<DropdownMenuItem<String>>((item) {
                            // Konversi ID ke String secara aman agar tidak crash/null
                            final String idVal = (item['id'] ?? 
                                                 item['id_bank'] ?? 
                                                 item['bank_sampah_id'] ?? 
                                                 '').toString();

                            final String namaBank = item['nama_bank_sampah'] ??
                                item['nama'] ??
                                item['name'] ??
                                'Bank Sampah #$idVal';

                            return DropdownMenuItem<String>(
                              value: idVal,
                              child: Text(namaBank, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (String? val) {
                            setState(() {
                              _selectedBankSampahId = val;
                            });
                          },
                        ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _beratController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Perkiraan Berat (Gram)',
                      border: OutlineInputBorder(),
                      suffixText: 'Gram',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135232),
                      ),
                      onPressed: _isSubmitting ? null : _submitData,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'KIRIM TIKET SETOR',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}