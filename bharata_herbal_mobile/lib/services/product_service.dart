import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/product_model.dart';

class ProductService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),

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

  Future<Product?> getProductById(int productId) async {
    try {
      final response = await dio.get('/products/$productId');
      final data = response.data?['data'];
      if (data != null) {
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get product by id error: $e');
      }
      return null;
    }
  }
}
