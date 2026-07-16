// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../utils/app_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
    required String preferredLanguage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'role': role,
          'preferred_language': preferredLanguage,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _saveSession(data['token'], data['user']);
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Server unreachable'};
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveSession(data['token'], data['user']);
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Server unreachable'};
    }
  }

  // Save token + user locally
  Future<void> _saveSession(String token, Map<String, dynamic> userData) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(userData));
    _currentUser = UserModel.fromJson(userData);
  }

  // Auto login from stored token
  Future<bool> autoLogin() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final userData = await _storage.read(key: _userKey);
      if (token == null || userData == null) return false;
      if (JwtDecoder.isExpired(token)) {
        await logout();
        return false;
      }
      _currentUser = UserModel.fromJson(jsonDecode(userData));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get token for API calls
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Logout
  Future<void> logout() async {
    await _storage.deleteAll();
    _currentUser = null;
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('${AppConfig.apiUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _storage.write(key: _userKey, value: jsonEncode(data['user']));
        _currentUser = UserModel.fromJson(data['user']);
        return {'success': true};
      }
      return {'success': false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Server unreachable'};
    }
  }
}
