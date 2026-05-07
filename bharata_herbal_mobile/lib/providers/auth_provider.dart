import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://192.168.0.104/api';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fungsi Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        String token = response.data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error Login: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Fungsi Register
  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '$_baseUrl/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error Register: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Cek apakah user sudah login
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null;
  }

  // Fungsi Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
