import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ProductService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),

      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<List<dynamic>> getProducts({String? search, String? category}) async {
    try {
      final response = await dio.get(
        '/products',
        queryParameters: {'search': search, 'category': category},
      );

      final data = response.data?['data']?['data'] ?? [];

      if (kDebugMode) {
        print('RAW PRODUCTS LENGTH: ${data.length}');
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Products error: $e');
      }
      return [];
    }
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await dio.get('/categories');
      final data = response.data['data'] ?? [];

      if (kDebugMode) {
        print('RAW CATEGORIES LENGTH: ${data.length}');
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Categories error: $e');
      }
      return [];
    }
  }
}
