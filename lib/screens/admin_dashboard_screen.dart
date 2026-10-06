import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'admin_deposit_screen.dart';
import 'admin_account_screen.dart';
import 'admin_scan_qr_screen.dart';
import 'admin_tiket_poin_screen.dart';
import 'admin_tiket_setor_screen.dart';
import 'admin_voucher_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color primaryGreen = Color(0xFF135232);
  static const Color pageBackground = Color(0xFFF4F7F5);
  static const Color softGreen = Color(0xFFE8F0EC);

  bool _isLoading = true;
  Map<String, dynamic> _data = {};
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _context = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    final res = await ApiService.getAdminDashboard();
    if (!mounted) return;

    setState(() {
      _data = res;
      _stats = (res['stats'] is Map)
          ? Map<String, dynamic>.from(res['stats'])
          : {};
      _context = (res['context'] is Map)
          ? Map<String, dynamic>.from(res['context'])
          : {};
      _isLoading = false;
    });
  }

  int _int(String key) => int.tryParse('${_stats[key] ?? 0}') ?? 0;
  double _double(String key) => double.tryParse('${_stats[key] ?? 0}') ?? 0;

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: pageBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_data['success'] != true) {
      return Scaffold(
        backgroundColor: pageBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  _data['message']?.toString() ?? 'Gagal memuat dashboard admin',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bankName = _context['nama_bank_sampah']?.toString() ?? 'Bank Sampah';

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryGreen,
                      child: const Icon(Icons.storefront, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bankName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Admin Bank Sampah',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadDashboard,
                      icon: const Icon(Icons.refresh),
                      color: primaryGreen,
                    ),
                    IconButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminAccountScreen(),
                          ),
                        );
                        if (mounted) {
                          _loadDashboard();
                        }
                      },
                      icon: const Icon(Icons.account_circle_outlined),
                      color: primaryGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Beranda Admin',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Kelola transaksi masyarakat pada bank sampah ini',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 4 : 2;
                    final width =
                        (constraints.maxWidth - ((columns - 1) * 10)) / columns;

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _statCard(
                          width,
                          'Menunggu',
                          '${_int('pending_tiket_setor')}',
                          'tiket setor',
                          Icons.pending_actions,
                        ),
                        _statCard(
                          width,
                          'Selesai',
                          '${_int('selesai_tiket_setor')}',
                          'setoran',
                          Icons.check_circle_outline,
                        ),
                        _statCard(
                          width,
                          'Total Berat',
                          _double('total_berat_kg').toStringAsFixed(2),
                          'Kg tervalidasi',
                          Icons.delete_outline,
                        ),
                        _statCard(
                          width,
                          'Total Poin',
                          '${_int('total_poin_setor')}',
                          'poin diberikan',
                          Icons.stars_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.dashboard_customize, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Menu Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Buka modul untuk memeriksa dan mengelola data nyata dari masyarakat',
                        style: TextStyle(color: Colors.white.withOpacity(.75), fontSize: 12),
                      ),
                      const SizedBox(height: 18),
                      _menuTile(
                        icon: Icons.delete_outline,
                        title: 'Periksa Tiket Setor',
                        subtitle: '${_int('pending_tiket_setor')} tiket menunggu',
                        onTap: () => _open(const AdminTiketSetorScreen()),
                      ),
                      _menuTile(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Tiket Poin',
                        subtitle: '${_int('pending_tiket_poin')} tiket menunggu',
                        onTap: () => _open(const AdminTiketPoinScreen()),
                      ),
                      _menuTile(
                        icon: Icons.card_giftcard,
                        title: 'Voucher',
                        subtitle: '${_int('total_voucher_diajukan')} voucher diajukan',
                        onTap: () => _open(const AdminVoucherScreen()),
                      ),
                      _menuTile(
                        icon: Icons.qr_code_scanner,
                        title: 'Scan QR',
                        subtitle: 'Cari tiket berdasarkan kode',
                        onTap: () => _open(const AdminScanQrScreen()),
                      ),
                      _menuTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Deposit',
                        subtitle: 'Lihat setoran yang sudah selesai',
                        onTap: () => _open(const AdminDepositScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    double width,
    String title,
    String value,
    String unit,
    IconData icon,
  ) {
    return SizedBox(
      width: width,
      child: Container(
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Icon(icon, size: 16, color: Colors.grey[700]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: softGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
