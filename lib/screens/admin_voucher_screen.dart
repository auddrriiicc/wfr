import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  static const Color primaryGreen = Color(0xFF135232);
  static const Color pageBackground = Color(0xFFF4F7F5);
  static const Color softGreen = Color(0xFFE8F0EC);

  bool _isLoading = true;
  List<dynamic> _rows = [];
  int _totalVoucher = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getAdminVoucher();
    if (!mounted) return;

    setState(() {
      _rows = res['data'] is List ? res['data'] : [];
      final summary = res['summary'];
      if (summary is Map) {
        _totalVoucher = int.tryParse('${summary['total_voucher'] ?? 0}') ?? 0;
        _totalPoints = int.tryParse('${summary['total_poin'] ?? 0}') ?? 0;
      } else {
        _totalVoucher = 0;
        _totalPoints = 0;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Voucher'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ?   ListView(
                children: [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(child: _summaryCard('Voucher', '$_totalVoucher', Icons.card_giftcard)),
                      const SizedBox(width: 10),
                      Expanded(child: _summaryCard('Poin', '$_totalPoints', Icons.stars_outlined)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Column(
                        children: [
                          Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Belum ada pengajuan voucher dari masyarakat'),
                        ],
                      ),
                    )
                  else
                    ..._rows.map((item) {
                      final row = Map<String, dynamic>.from(item as Map);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: softGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.card_giftcard, color: primaryGreen),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row['nama_lengkap']?.toString() ?? 'Masyarakat',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      row['kode_tiket']?.toString() ?? '#${row['id'] ?? '-'}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${row['jumlah_voucher'] ?? 0} voucher',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text('${row['jumlah_poin'] ?? 0} poin',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, size: 17, color: Colors.grey[700]),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
        ],
      ),
    );
  }
}
