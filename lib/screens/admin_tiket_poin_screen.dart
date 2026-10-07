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
  final Set<int> _processingIds = <int>{};
  List<dynamic> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    final data = await ApiService.getAdminTiketPoin();
    if (!mounted) return;
    setState(() {
      _rows = data;
      _isLoading = false;
    });
  }

  bool _isPending(dynamic value) {
    return const ['pending', 'menunggu', 'diproses']
        .contains((value ?? '').toString().toLowerCase());
  }

  Future<void> _approve(int id) async {
    if (_processingIds.contains(id)) return;

    setState(() => _processingIds.add(id));
    final result = await ApiService.approveAdminTiketPoin(id);

    if (!mounted) return;
    setState(() => _processingIds.remove(id));

    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              (success ? 'Tiket berhasil disetujui.' : 'Tiket gagal diproses.'),
        ),
        backgroundColor: success ? primaryGreen : Colors.red,
      ),
    );

    if (success) {
      await _load();
    }
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
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 260),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _rows.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 220),
                      Icon(Icons.confirmation_number_outlined,
                          size: 64, color: Colors.grey),
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
                      final raw = _rows[index];
                      if (raw is! Map) return const SizedBox.shrink();
                      final row = Map<String, dynamic>.from(raw);
                      final status = row['status']?.toString() ?? 'pending';
                      final pending = _isPending(row['status']);
                      final id = int.tryParse('${row['id'] ?? ''}');
                      final processing = id != null && _processingIds.contains(id);

                      return Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: softGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.stars_outlined,
                                      color: primaryGreen),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row['nama_lengkap']?.toString() ??
                                            'Masyarakat',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        row['kode_tiket']?.toString() ??
                                            '#${row['id'] ?? '-'}',
                                        style: TextStyle(
                                            color: Colors.grey[600], fontSize: 11),
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
                                _statusChip(status, pending),
                              ],
                            ),
                            if (pending && id != null) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: processing ? null : () => _approve(id),
                                  icon: processing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check, size: 18),
                                  label: Text(
                                    processing ? 'Memproses...' : 'ACC Tiket Poin',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
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
