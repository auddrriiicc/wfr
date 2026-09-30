import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Setor'), backgroundColor: Colors.blue[700]),
      body: FutureBuilder<List<dynamic>>(
        // DIUBAH: Gunakan ApiService.getRiwayatSetor()
        future: ApiService.getRiwayatSetor(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada riwayat transaksi'));
          }

          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text('Status: ${item['status'] ?? '-'}'),
                  subtitle: Text('Berat: ${item['berat_estimasi'] ?? item['perkiraan_berat'] ?? 0} gram'),
                  trailing: Text(
                    item['created_at'] != null ? item['created_at'].toString().split('T')[0] : '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}