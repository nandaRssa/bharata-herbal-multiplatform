import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AuthService {
  final Dio dio = Dio();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
