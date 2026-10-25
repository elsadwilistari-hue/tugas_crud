import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  static const String _baseUrl = 'https://reqres.in/api';

  // GANTI dengan API key dari https://app.reqres.in
  static const String _apiKey = "free_user_3LAkXJ92Q96YPE7TdRcLDfm21WW";

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
  };

  static const Duration _timeout = Duration(seconds: 15);

  // Validasi status code, lalu parse JSON
  dynamic _handle(http.Response res, {List<int> ok = const [200, 201]}) {
    if (!ok.contains(res.statusCode)) {
      switch (res.statusCode) {
        case 401:
        case 403:
          throw Exception(
              'Akses ditolak (${res.statusCode}). Periksa API key reqres.in kamu.');
        case 404:
          throw Exception('Data tidak ditemukan (404).');
        case 429:
          throw Exception('Terlalu banyak request (429). Coba lagi nanti.');
        default:
          throw Exception('Server error (kode ${res.statusCode}).');
      }
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  // Ubah error teknis menjadi pesan yang mudah dibaca
  Exception _toFriendly(Object e) {
    if (e is SocketException || e is http.ClientException) {
      return Exception('Tidak ada koneksi internet. Periksa jaringan kamu.');
    }
    if (e is TimeoutException) {
      return Exception('Koneksi terlalu lama (timeout). Coba lagi.');
    }
    if (e is FormatException) {
      return Exception('Format data dari server tidak valid.');
    }
    if (e is Exception) return e;
    return Exception('Terjadi kesalahan: $e');
  }

  // READ - GET
  Future<List<UserModel>> getUsers({int page = 1}) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/users?page=$page'), headers: _headers)
          .timeout(_timeout);
      final data = _handle(res, ok: [200]);
      return (data['data'] as List)
          .map((j) => UserModel.fromJson(j))
          .toList();
    } catch (e) {
      throw _toFriendly(e);
    }
  }

  // CREATE - POST
  Future<Map<String, dynamic>> createUser(String name, String job) async {
    try {
      final res = await http
          .post(
        Uri.parse('$_baseUrl/users'),
        headers: _headers,
        body: jsonEncode({'name': name, 'job': job}),
      )
          .timeout(_timeout);
      return _handle(res, ok: [200, 201]);
    } catch (e) {
      throw _toFriendly(e);
    }
  }

  // UPDATE - PUT
  Future<Map<String, dynamic>> updateUser(
      int id, String name, String job) async {
    try {
      final res = await http
          .put(
        Uri.parse('$_baseUrl/users/$id'),
        headers: _headers,
        body: jsonEncode({'name': name, 'job': job}),
      )
          .timeout(_timeout);
      return _handle(res, ok: [200]);
    } catch (e) {
      throw _toFriendly(e);
    }
  }

  // DELETE
  Future<void> deleteUser(int id) async {
    try {
      final res = await http
          .delete(Uri.parse('$_baseUrl/users/$id'), headers: _headers)
          .timeout(_timeout);
      _handle(res, ok: [200, 204]);
    } catch (e) {
      throw _toFriendly(e);
    }
  }
}