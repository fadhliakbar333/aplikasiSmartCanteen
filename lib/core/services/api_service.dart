import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiService {
  final http.Client _client;

  ApiService([http.Client? client]) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(AppConstants.apiTimeout);

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _parseResponse(http.Response response) async {
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final errorMessage =
        json['message'] as String? ?? 'Terjadi kesalahan server';
    throw Exception(errorMessage);
  }

  Future<Map<String, dynamic>> login(String email, String password) {
    return post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> loginAdmin(String email, String password) {
    return post(
      '/admin/login',
      {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) {
    return post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }
}
