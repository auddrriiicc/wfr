import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminTiketSetorScreen extends StatefulWidget {
  const AdminTiketSetorScreen({super.key});

  @override
  State<AdminTiketSetorScreen> createState() => _AdminTiketSetorScreenState();
}

class _AdminTiketSetorScreenState extends State<AdminTiketSetorScreen> {
  static const Color primaryGreen = Color(0xFF135232);
  static const Color pageBackground = Color(0xFFF4F7F5);
  static const Color softGreen = Color(0xFFE8F0EC);

  bool _isLoading = true;
  List<dynamic> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getAdminTickets();
    if (!mounted) return;
    setState(() {
      _tickets = data;
      _isLoading = false;
    });
  }

  String _status(dynamic value) => (value ?? 'pending').toString();

  bool _isPending(dynamic value) {
    return ['pending', 'menunggu', 'diproses']
        .contains(_status(value).toLowerCase());
  }

  String _num(dynamic value, {int fractionDigits = 2}) {
    final number = double.tryParse('$value') ?? 0;
    return number.toStringAsFixed(fractionDigits);
  }

  Future<void> _approve(Map<String, dynamic> ticket) async {
    final controller = TextEditingController(
      text: _num(ticket['berat'], fractionDigits: 2),
    );

    final actualWeight = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Periksa Tiket Setor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiket: ${ticket['kode_tiket'] ?? '-'}'),
              const SizedBox(height: 4),
              Text('Masyarakat: ${ticket['nama_lengkap'] ?? 'Masyarakat'}'),
              const SizedBox(height: 16),
              const Text(
                'Berat aktual (Kg)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 2.50',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Poin final = berat aktual × 1.000 poin/Kg',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text.replaceAll(',', '.'));
                if (value == null || value <= 0) return;
                Navigator.pop(dialogContext, value);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: const Text('ACC', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (actualWeight == null || !mounted) return;

    final id = int.tryParse('${ticket['id']}');
    if (id == null) return;

    final result = await ApiService.approveAdminTicket(id, actualWeight);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Tiket berhasil di-ACC. ${result['data']?['poin_final'] ?? 0} poin ditambahkan.'
              : (result['message']?.toString() ?? 'Gagal memproses tiket'),
        ),
        backgroundColor: result['success'] == true ? primaryGreen : Colors.red,
      ),
    );

    if (result['success'] == true) {
      _loadTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Periksa Tiket Setor'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: _isLoading
            ?   ListView(
                children: [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _tickets.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 220),
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Center(child: Text('Belum ada tiket setor')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ticket = Map<String, dynamic>.from(_tickets[index] as Map);
                      final pending = _isPending(ticket['status']);
                      final status = _status(ticket['status']);
                      final finalWeight = ticket['berat_actual'];
                      final finalPoints = ticket['poin_final'];

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
                                  child: const Icon(Icons.delete_outline, color: primaryGreen),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ticket['kode_tiket']?.toString() ?? '-',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        ticket['nama_lengkap']?.toString() ?? 'Masyarakat',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                _statusChip(status),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _detailRow('Berat estimasi', '${_num(ticket['berat'])} Kg'),
                            _detailRow('Estimasi poin', '${ticket['estimasi_poin'] ?? 0} poin'),
                            if (finalWeight != null)
                              _detailRow('Berat aktual', '${_num(finalWeight)} Kg'),
                            if (finalPoints != null)
                              _detailRow('Poin final', '$finalPoints poin'),
                            if (pending) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _approve(ticket),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Periksa & ACC'),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final pending = _isPending(status);
    final color = pending ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
