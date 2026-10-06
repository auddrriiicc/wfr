import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminDepositScreen extends StatefulWidget {
  const AdminDepositScreen({super.key});

  @override
  State<AdminDepositScreen> createState() => _AdminDepositScreenState();
}

class _AdminDepositScreenState extends State<AdminDepositScreen> {
  static const Color primaryGreen = Color(0xFF135232);
  static const Color pageBackground = Color(0xFFF4F7F5);
  static const Color softGreen = Color(0xFFE8F0EC);

  bool _isLoading = true;
  List<dynamic> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getAdminDeposit();
    if (!mounted) return;
    setState(() {
      _rows = data;
      _isLoading = false;
    });
  }

  String _weight(dynamic value) {
    final number = double.tryParse('$value') ?? 0;
    return number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Deposit'),
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
            : _rows.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 220),
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Center(child: Text('Belum ada deposit/setoran selesai')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = Map<String, dynamic>.from(_rows[index] as Map);
                      final weight = row['berat_actual'] ?? row['berat'] ?? 0;

                      return Container(
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
                              child: const Icon(Icons.account_balance_wallet_outlined, color: primaryGreen),
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
                                    row['kode_tiket']?.toString() ?? '-',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_weight(weight)} Kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${row['poin_final'] ?? 0} poin',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
