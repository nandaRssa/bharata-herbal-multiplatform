import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _service = AuthService();

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isLoggedIn => _user != null;

  // Cek token saat app startup
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      _user = await _service.getMe();
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.login(email, password);
      if (response['success'] == true) {
        final token = response['data']['token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        _user = User.fromJson(response['data']['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(
    String name,
    String email,
    String phone,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.register(
        name,
        email,
        phone,
        password,
        confirmPassword,
      );
      if (response['success'] == true) {
        final token = response['data']['token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        _user = User.fromJson(response['data']['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Register error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _service.logout();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(
    String name,
    String email,
    String phone,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final ok = await _service.updateProfile(name, email, phone);
      if (ok) {
        _user = await _service.getMe();
      }
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      debugPrint('Update profile error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updatePassword(
    String current,
    String newPass,
    String confirm,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final ok = await _service.updatePassword(current, newPass, confirm);
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      debugPrint('Update password error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<String?> uploadPhoto(String filePath) async {
    _isLoading = true;
    notifyListeners();
    try {
      final avatarUrl = await _service.uploadPhoto(filePath);
      if (avatarUrl != null) {
        _user = await _service.getMe();
      }
      _isLoading = false;
      notifyListeners();
      return avatarUrl;
    } catch (e) {
      debugPrint('Upload photo error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }
}
