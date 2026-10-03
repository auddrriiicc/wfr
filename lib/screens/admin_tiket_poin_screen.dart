import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminTiketPoinScreen extends StatefulWidget {
  const AdminTiketPoinScreen({super.key});

  @override
  State<AdminTiketPoinScreen> createState() => _AdminTiketPoinScreenState();
}

class _AdminTiketPoinScreenState extends State<AdminTiketPoinScreen> {
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
    final data = await ApiService.getAdminTiketPoin();
    if (!mounted) return;
    setState(() {
      _rows = data;
      _isLoading = false;
    });
  }

  bool _isPending(dynamic value) {
    return ['pending', 'menunggu', 'diproses']
        .contains((value ?? '').toString().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Tiket Poin'),
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
                      Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Center(child: Text('Belum ada tiket poin dari masyarakat')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = Map<String, dynamic>.from(_rows[index] as Map);
                      final status = row['status']?.toString() ?? 'pending';
                      final pending = _isPending(row['status']);

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showDetail(row),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                                child: const Icon(Icons.stars_outlined, color: primaryGreen),
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
                                    const SizedBox(height: 5),
                                    Text(
                                      '${row['jumlah_poin'] ?? 0} poin  •  ${row['jumlah_voucher'] ?? 0} voucher',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _statusChip(status, pending),
                                  const SizedBox(height: 8),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> row) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Tiket Poin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _row('Masyarakat', row['nama_lengkap']),
                _row('Kode Tiket', row['kode_tiket']),
                _row('Jumlah Poin', '${row['jumlah_poin'] ?? 0} poin'),
                _row('Jumlah Voucher', '${row['jumlah_voucher'] ?? 0} voucher'),
                _row('Status', row['status'] ?? '-'),
                if (row['catatan'] != null)
                  _row('Catatan', row['catatan']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _statusChip(String status, bool pending) {
    final color = pending ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
