import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class ApiService {
  static String get baseUrl => ApiConstants.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static List<dynamic> _decodeList(String body) {
    final data = _decode(body);
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }
    return [];
  }

  static Map<String, dynamic> _mapOrError(
    http.Response response,
    String fallback,
  ) {
    final data = _decode(response.body);
    if (data is Map<String, dynamic>) return data;
    return {
      'success': false,
      'message': '$fallback (HTTP ${response.statusCode})',
    };
  }

  // --------------------------------------------------------------------------
  // Masyarakat
  // --------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: await _getHeaders(),
      );

      return _mapOrError(response, 'Response profile tidak valid');
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  static Future<List<dynamic>> getBankSampahList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/bank-sampahs'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200 ? _decodeList(response.body) : [];
    } catch (e) {
      print('ERROR getBankSampahList: $e');
      return [];
    }
  }

  static Future<bool> createTiketSampah(
    double berat,
    dynamic bankSampahId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v2/tiketsetorsampahs'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'bank_sampah_id': bankSampahId,
          'berat': berat,
        }),
      );

      print('>>> CREATE TIKET STATUS: ${response.statusCode}');
      print('>>> CREATE TIKET BODY: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('>>> ERROR CREATE TIKET: $e');
      return false;
    }
  }

  static Future<bool> createTiketPoin(
    int jumlahPoin,
    int jumlahVoucher,
    dynamic bankSampahId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v2/tikettukarpoin'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'jumlah_poin': jumlahPoin,
          'jumlah_voucher': jumlahVoucher,
          'bank_sampah_id': bankSampahId,
        }),
      );

      print('>>> CREATE TIKET POIN STATUS: ${response.statusCode}');
      print('>>> CREATE TIKET POIN BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('>>> ERROR CREATE TIKET POIN: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getArtikels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/artikels'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 ? _decodeList(response.body) : [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getRiwayatSetor() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/tiketsetorsampahs'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 ? _decodeList(response.body) : [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getRiwayatPoin() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/tikettukarpoin'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 ? _decodeList(response.body) : [];
    } catch (_) {
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // Admin Bank Sampah
  // --------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/admin/dashboard'),
        headers: await _getHeaders(),
      );
      return _mapOrError(response, 'Response dashboard admin tidak valid');
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memuat dashboard admin: $e',
      };
    }
  }

  static Future<List<dynamic>> getAdminTickets({String? status}) async {
    try {
      final uri = Uri.parse('$baseUrl/v2/admin/tiket-sampah').replace(
        queryParameters: status == null || status.isEmpty
            ? null
            : {'status': status},
      );
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 ? _decodeList(response.body) : [];
    } catch (e) {
      print('ERROR getAdminTickets: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> approveAdminTicket(
    int ticketId,
    double beratActual,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v2/admin/tiket-sampah/$ticketId/approve'),
        headers: await _getHeaders(),
        body: jsonEncode({'berat_actual': beratActual}),
      );
      return _mapOrError(response, 'Response approval tidak valid');
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memproses tiket: $e',
      };
    }
  }

  static Future<List<dynamic>> getAdminTiketPoin() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/admin/tiket-poin'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 ? _decodeList(response.body) : [];
    } catch (e) {
      print('ERROR getAdminTiketPoin: $e');
      return [];
    }
  }

  // Method yang sebelumnya hilang dan menyebabkan error di admin_tiket_poin_screen.
  static Future<Map<String, dynamic>> approveAdminTiketPoin(
    dynamic ticketId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v2/admin/tiket-poin/${ticketId.toString()}/approve'),
        headers: await _getHeaders(),
      );
      return _mapOrError(response, 'Gagal memproses tiket poin');
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memproses tiket poin: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getAdminVoucher() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/admin/voucher'),
        headers: await _getHeaders(),
      );
      return _mapOrError(response, 'Response voucher tidak valid');
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memuat voucher: $e',
        'data': [],
      };
    }
  }

  static Future<List<dynamic>> getAdminDeposit() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/admin/deposit'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 ? _decodeList(response.body) : [];
    } catch (e) {
      print('ERROR getAdminDeposit: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> scanAdminQr(String kode) async {
    try {
      final uri = Uri.parse('$baseUrl/v2/admin/scan-qr').replace(
        queryParameters: {'kode': kode},
      );
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );
      return _mapOrError(response, 'Response scan QR tidak valid');
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memeriksa QR/tiket: $e',
      };
    }
  }
}
