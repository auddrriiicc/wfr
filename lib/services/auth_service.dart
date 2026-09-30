import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Import XFile
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AuthService {
  // FUNGSI REGISTER DENGAN UPLOAD KTP (SUPPORT WEB & MOBILE)
  Future<Map<String, dynamic>> register({
    required String nik,
    required String nama,
    required String username,
    required String noHp,
    required String alamat,
    required String password,
    XFile? fotoKtp,
  }) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}/register");
    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll({'Accept': 'application/json'});

    request.fields['nik'] = nik;
    request.fields['nama'] = nama;
    request.fields['username'] = username;
    request.fields['no_hp'] = noHp;
    request.fields['alamat'] = alamat;
    request.fields['password'] = password;

    // Attach File Foto KTP menggunakan bytes (Support Web & Mobile)
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

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Registrasi Berhasil!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal mendaftar.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

 // FUNGSI LOGIN
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/login");
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

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return {'success': false, 'message': 'Respon server tidak valid'};
      }

      final Map<String, dynamic> data = decoded;

      if (response.statusCode == 200 && data['success'] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Ambil token secara aman tanpa memicu TypeError
        String token = '';
        if (data['token'] != null) {
          token = data['token'].toString();
        } else if (data['data'] != null && data['data'] is Map && data['data']['token'] != null) {
          token = data['data']['token'].toString();
        }

        if (token.isNotEmpty) {
          await prefs.setString('token', token);
        }

        return {
          'success': true,
          'message': (data['message'] ?? 'Login berhasil').toString(),
          'role': (data['role'] ?? 'Masyarakat').toString(),
          'user': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': (data['message'] ?? 'Login gagal').toString(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi: $e',
      };
    }
  }
}