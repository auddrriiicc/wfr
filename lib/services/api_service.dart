import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiService {
  // Helper Header untuk Otentikasi
  static Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Ambil Data Profile / User (Untuk Poin & Statistik Beranda)
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profile'),
        headers: await _getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // 2. Ambil Daftar Bank Sampah (Untuk Dropdown)
static Future<List<dynamic>> getBankSampahList() async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/v2/bank-sampahs');
    print('>>> GET REQUEST TO: $url');
    
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    print('>>> STATUS CODE: ${response.statusCode}');
    print('>>> RESPONSE BODY: ${response.body}');

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);

      // Jika backend membungkus hasilnya dalam key 'data'
      if (resData is Map && resData.containsKey('data')) {
        return resData['data'] as List<dynamic>;
      } 
      // Jika backend langsung mengembalikan Array List []
      else if (resData is List) {
        return resData;
      }
    } else {
      print('>>> GAGAL FETCH DATA! Status Code: ${response.statusCode}');
    }
    return [];
  } catch (e) {
    print('>>> EXCEPTION / KONEKSI ERROR getBankSampahList: $e');
    return [];
  }
}
  // 3. Simpan Tiket Setor Sampah
  static Future<bool> createTiketSampah(int beratGram, dynamic bankSampahId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/v2/tiketsetorsampahs'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'berat_estimasi': beratGram,
          'bank_sampah_id': bankSampahId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 4. Simpan Tiket Tukar Poin
  static Future<bool> createTiketPoin(int jumlahPoin, int jumlahVoucher, dynamic bankSampahId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/v2/tikettukarpoin'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'jumlah_poin': jumlahPoin,
          'jumlah_voucher': jumlahVoucher,
          'bank_sampah_id': bankSampahId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 5. Ambil Daftar Artikel (Edukasi)
  static Future<List<dynamic>> getArtikels() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/v2/artikels'),
        headers: await _getHeaders(),
      );
      final data = jsonDecode(response.body);
      return data['data'] ?? (data is List ? data : []);
    } catch (e) {
      return [];
    }
  }

  // 6. Ambil Riwayat Tiket Setor Sampah
  static Future<List<dynamic>> getRiwayatSetor() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/v2/tiketsetorsampahs'),
        headers: await _getHeaders(),
      );
      final data = jsonDecode(response.body);
      return data['data'] ?? (data is List ? data : []);
    } catch (e) {
      return [];
    }
  }

  // 7. Ambil Riwayat Tiket Tukar Poin
  static Future<List<dynamic>> getRiwayatPoin() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/v2/tikettukarpoin'),
        headers: await _getHeaders(),
      );
      final data = jsonDecode(response.body);
      return data['data'] ?? (data is List ? data : []);
    } catch (e) {
      return [];
    }
  }
}