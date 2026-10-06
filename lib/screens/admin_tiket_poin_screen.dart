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
  final Set<String> _processing = <String>{};
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
    final status = (value ?? '').toString().trim().toLowerCase();
    return status == 'pending' || status == 'menunggu' || status == 'diproses';
  }

  String _id(dynamic value) => value?.toString() ?? '';

  Future<void> _approve(dynamic id) async {
    final key = _id(id);
    if (key.isEmpty || _processing.contains(key)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Setujui Tiket Poin?'),
          content: const Text(
            'Poin masyarakat akan dikurangi dan tiket berubah menjadi selesai.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: const Text(
                'Setujui',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _processing.add(key));

    final result = await ApiService.approveAdminTiketPoin(id);
    if (!mounted) return;

    setState(() => _processing.remove(key));

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Tiket poin berhasil disetujui.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Gagal menyetujui tiket poin.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetail(Map<String, dynamic> row) {
    final pending = _isPending(row['status']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Tiket Poin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _detailRow('Masyarakat', row['nama_lengkap']),
                _detailRow('Username', row['username']),
                _detailRow('Kode Tiket', row['kode_tiket']),
                _detailRow('Jumlah Poin', '${row['jumlah_poin'] ?? 0} poin'),
                _detailRow(
                  'Jumlah Voucher',
                  '${row['jumlah_voucher'] ?? 0} voucher',
                ),
                _detailRow('Status', row['status']),
                if (row['catatan'] != null)
                  _detailRow('Catatan', row['catatan']),
                if (pending && row['id'] != null) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _approve(row['id']);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Setujui Tiket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(width: 18),
          Expanded(
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

  Widget _statusChip(String status) {
    final pending = _isPending(status);
    final color = pending ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
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
                  SizedBox(height: 280),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _rows.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 220),
                      Center(
                        child: Icon(
                          Icons.confirmation_number_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 12),
                      Center(child: Text('Belum ada tiket poin dari masyarakat')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final raw = _rows[index];
                      if (raw is! Map) return const SizedBox.shrink();

                      final row = Map<String, dynamic>.from(raw);
                      final status = row['status']?.toString() ?? 'pending';
                      final pending = _isPending(status);
                      final idKey = _id(row['id']);
                      final busy = _processing.contains(idKey);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showDetail(row),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: softGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.stars_outlined,
                                  color: primaryGreen,
                                ),
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
                                      row['kode_tiket']?.toString() ?? '#$idKey',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${row['jumlah_poin'] ?? 0} poin • ${row['jumlah_voucher'] ?? 0} voucher',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryGreen,
                                      ),
                                    ),
                                    if (pending) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: busy ? null : () => _approve(row['id']),
                                          icon: busy
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.check, size: 16),
                                          label: Text(busy ? 'Memproses...' : 'Setujui'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(9),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _statusChip(status),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
