import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<Options> _authOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await _dio.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data;
  }

  Future<void> logout() async {
    final options = await _authOptions();
    try {
      await _dio.post('/logout', options: options);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<User?> getMe() async {
    final options = await _authOptions();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _dio.get('/me', options: options);
      if (response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> updateProfile(String name, String email, String phone) async {
    final options = await _authOptions();
    final response = await _dio.put(
      '/profile',
      data: {'name': name, 'email': email, 'phone': phone},
      options: options,
    );
    return response.data['success'] == true;
  }

  Future<bool> updatePassword(
    String current,
    String newPass,
    String confirm,
  ) async {
    final options = await _authOptions();
    final response = await _dio.put(
      '/profile/password',
      data: {
        'current_password': current,
        'password': newPass,
        'password_confirmation': confirm,
      },
      options: options,
    );
    return response.data['success'] == true;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post('/forgot-password', data: {'email': email});
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String token,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await _dio.post('/reset-password', data: {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return response.data;
  }

  Future<String?> uploadPhoto(String filePath) async {
    final options = await _authOptions();
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath, filename: 'profile.jpg'),
    });
    final response = await _dio.post(
      '/profile/photo',
      data: formData,
      options: options,
    );
    if (response.data['success'] == true) {
      return response.data['data']['avatar'] as String?;
    }
    return null;
  }
}
