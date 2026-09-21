import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final String message;
  final int statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message = '',
    required this.statusCode,
  });
}

class ApiClient {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  static String? _inMemoryToken;

  static Future<String?> getToken() async {
    if (_inMemoryToken != null) return _inMemoryToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString(_tokenKey);
      if (t != null && t.isNotEmpty) {
        _inMemoryToken = t;
        return t;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final t = await _storage.read(key: _tokenKey);
        _inMemoryToken = t;
        return t;
      } catch (_) {}
    }
    return null;
  }

  static Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _storage.write(key: _tokenKey, value: token);
      } catch (_) {}
    }
  }

  static Future<void> clearToken() async {
    _inMemoryToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _storage.delete(key: _tokenKey);
      } catch (_) {}
    }
  }

  static Future<Map<String, String>> _buildHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    String baseUrl = AppConstants.apiBaseUrl;
    if (kIsWeb && baseUrl.contains('10.0.2.2')) {
      baseUrl = 'http://localhost:3000/api';
    }
    final fullUrl = path.startsWith('http') ? path : '$baseUrl$path';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    try {
      final headers = await _buildHeaders();
      final uri = _buildUri(path, queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString(), message: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _buildHeaders();
      final uri = _buildUri(path);
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString(), message: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _buildHeaders();
      final uri = _buildUri(path);
      final response = await http
          .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString(), message: e.toString(), statusCode: 0);
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final msg = data is Map ? (data['message'] ?? data['error'] ?? '') : '';
      return ApiResponse(
        success: isSuccess,
        data: data,
        message: msg.toString(),
        error: !isSuccess ? msg.toString() : null,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        data: response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
