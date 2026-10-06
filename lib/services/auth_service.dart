import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AuthService {
  Future<Map<String, String>> _headers({bool json = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Register Masyarakat
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> register({
    required String nik,
    required String nama,
    required String username,
    required String noHp,
    required String alamat,
    required String password,
    XFile? fotoKtp,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/register');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';
    request.fields['nik'] = nik;
    request.fields['nama'] = nama;
    request.fields['username'] = username;
    request.fields['no_hp'] = noHp;
    request.fields['alamat'] = alamat;
    request.fields['password'] = password;

    try {
      if (fotoKtp != null) {
        final bytes = await fotoKtp.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_ktp',
            bytes,
            filename: fotoKtp.name,
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = _decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 &&
          data is Map<String, dynamic>) {
        return {
          'success': data['success'] == true,
          'message': data['message']?.toString() ?? 'Registrasi berhasil.',
        };
      }

      return {
        'success': false,
        'message': data is Map<String, dynamic>
            ? (data['message']?.toString() ?? 'Gagal mendaftar.')
            : 'Gagal mendaftar. HTTP ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // --------------------------------------------------------------------------
  // Login
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Jangan biarkan token akun sebelumnya dipakai akun berikutnya.
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user_id');
    await prefs.remove('bank_sampah_id');
    await prefs.remove('bank_sampah_name');

    final url = Uri.parse('${ApiConstants.baseUrl}/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'identifier': username,
          'password': password,
        }),
      );

      final decoded = _decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Respon server tidak valid.',
        };
      }

      if (response.statusCode != 200 || decoded['success'] != true) {
        return {
          'success': false,
          'message': decoded['message']?.toString() ?? 'Login gagal.',
        };
      }

      final token = decoded['token']?.toString() ?? '';
      final role = decoded['role']?.toString() ?? 'Masyarakat';
      final user = decoded['data'];
      final bank = decoded['bank_sampah'];

      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Login berhasil tetapi token tidak diterima server.',
        };
      }

      await prefs.setString('token', token);
      await prefs.setString('role', role);

      if (user is Map) {
        final userId = user['id'];
        if (userId != null) {
          await prefs.setString('user_id', userId.toString());
        }
      }

      if (bank is Map) {
        if (bank['id'] != null) {
          await prefs.setString('bank_sampah_id', bank['id'].toString());
        }
        if (bank['nama_bank_sampah'] != null) {
          await prefs.setString(
            'bank_sampah_name',
            bank['nama_bank_sampah'].toString(),
          );
        }
      }

      return {
        'success': true,
        'message': decoded['message']?.toString() ?? 'Login berhasil',
        'role': role,
        'user': user,
        'bank_sampah': bank,
        'token': token,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi: $e',
      };
    }
  }

  // --------------------------------------------------------------------------
  // Ubah password akun yang sedang login
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/change-password'),
        headers: await _headers(),
        body: jsonEncode({
          'password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = _decode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': false,
        'message': 'Response ubah password tidak valid.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengubah password: $e',
      };
    }
  }

  // --------------------------------------------------------------------------
  // Logout
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/logout'),
        headers: await _headers(),
      );

      final data = _decode(response.body);
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('user_id');
      await prefs.remove('bank_sampah_id');
      await prefs.remove('bank_sampah_name');

      if (data is Map<String, dynamic>) return data;

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': 'Logout berhasil.',
      };
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('user_id');
      await prefs.remove('bank_sampah_id');
      await prefs.remove('bank_sampah_name');

      return {
        'success': false,
        'message': 'Logout lokal selesai. Server tidak dapat dihubungi: $e',
      };
    }
  }
}
