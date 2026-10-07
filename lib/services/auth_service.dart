import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AuthService {
  Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      if (includeContentType) 'Content-Type': 'application/json',
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

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user_id');
    await prefs.remove('bank_sampah_id');
    await prefs.remove('bank_sampah_name');
  }

  // --------------------------------------------------------------------------
  // REGISTER MASYARAKAT
  // Email TIDAK diperlukan.
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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
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
      return {
        'success': false,
        'message': 'Koneksi error: $e',
      };
    }
  }

  // --------------------------------------------------------------------------
  // LOGIN
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    // Hapus session akun sebelumnya sebelum login akun baru.
    await _clearSession();

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

      final data = _decode(response.body);

      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Respon server tidak valid.',
        };
      }

      if (response.statusCode != 200 || data['success'] != true) {
        return {
          'success': false,
          'message': data['message']?.toString() ?? 'Login gagal.',
        };
      }

      final token = data['token']?.toString() ?? '';
      final role = data['role']?.toString() ?? 'Masyarakat';
      final user = data['data'];
      final bankSampah = data['bank_sampah'];

      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Login berhasil tetapi token tidak diterima server.',
        };
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', token);
      await prefs.setString('role', role);

      if (user is Map) {
        final userId = user['id'];
        if (userId != null) {
          await prefs.setString('user_id', userId.toString());
        }
      }

      if (bankSampah is Map) {
        final bankId = bankSampah['id'];
        final bankName = bankSampah['nama_bank_sampah'];

        if (bankId != null) {
          await prefs.setString('bank_sampah_id', bankId.toString());
        }

        if (bankName != null) {
          await prefs.setString('bank_sampah_name', bankName.toString());
        }
      }

      return {
        'success': true,
        'message': data['message']?.toString() ?? 'Login berhasil.',
        'role': role,
        'user': user,
        'bank_sampah': bankSampah,
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
  // UBAH PASSWORD
  // Mendukung pemanggilan positional:
  // changePassword(passwordLama, passwordBaru)
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
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
  // LOGOUT
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      if (token.isNotEmpty) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/logout'),
          headers: await _headers(),
        );

        final data = _decode(response.body);

        await _clearSession();

        if (data is Map<String, dynamic>) {
          return data;
        }

        return {
          'success': response.statusCode >= 200 &&
              response.statusCode < 300,
          'message': 'Logout berhasil.',
        };
      }
    } catch (_) {
      // Session lokal tetap dihapus walaupun server tidak dapat dihubungi.
    }

    await _clearSession();

    return {
      'success': true,
      'message': 'Logout berhasil.',
    };
  }
}
