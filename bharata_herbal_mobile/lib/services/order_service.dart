import 'dart:io';
import 'package:dio/dio.dart';
import 'base_service.dart';
import '../models/order_model.dart';

class OrderService extends BaseService {
  Future<Map<String, dynamic>> getOrders({String? status, int page = 1}) async {
    final options = await authOptions();
    final response = await dio.get(
      '/orders',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'per_page': 20,
      },
      options: options,
    );
    final paginated = response.data['data'];
    final data = paginated['data'] as List<dynamic>? ?? [];
    final orders = data.map((o) => Order.fromJson(o)).toList();
    final currentPage = paginated['current_page'] ?? 1;
    final lastPage = paginated['last_page'] ?? 1;
    return {
      'orders': orders,
      'has_more': currentPage < lastPage,
    };
  }

  Future<Order> getOrderDetail(int orderId) async {
    final options = await authOptions();
    final response = await dio.get('/orders/$orderId', options: options);
    return Order.fromJson(response.data['data']);
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    final options = await authOptions();
    final response = await dio.post(
      '/orders/$orderId/cancel',
      data: {'cancel_reason': reason},
      options: options,
    );
    return response.data['success'] == true;
  }

  Future<Map<String, dynamic>> payNow(int orderId) async {
    final options = await authOptions();
    final response = await dio.post('/orders/$orderId/pay', options: options);
    return response.data['data'] ?? {};
  }

  Future<bool> buyAgain(int orderId) async {
    final options = await authOptions();
    final response = await dio.post('/orders/$orderId/buy-again', options: options);
    return response.data['success'] == true;
  }

  Future<bool> submitReview(int orderId, int productId, int rating, String comment, {File? image}) async {
    final options = await authOptions();
    
    dynamic data;
    if (image != null) {
      final map = <String, dynamic>{
        'product_id': productId,
        'rating': rating,
      };
      if (comment.trim().isNotEmpty) {
        map['comment'] = comment.trim();
      }
      map['image'] = await MultipartFile.fromFile(image.path, filename: 'review_${DateTime.now().millisecondsSinceEpoch}.jpg');
      data = FormData.fromMap(map);
    } else {
      data = {
        'product_id': productId,
        'rating': rating,
        if (comment.trim().isNotEmpty) 'comment': comment.trim(),
      };
    }

    try {
      final response = await dio.post(
        '/orders/$orderId/reviews',
        data: data,
        options: options,
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengirim ulasan';
      throw Exception(msg);
    }
  }

  /// Customer confirms they received the shipped order → marks as completed.
  Future<bool> confirmReceived(int orderId) async {
    final options = await authOptions();
    final response = await dio.post(
      '/orders/$orderId/confirm-received',
      options: options,
    );
    return response.data['success'] == true;
  }

  /// Upload payment proof image (for bank transfer orders).
  Future<String> uploadPaymentProof(int orderId, File imageFile) async {
    final options = await authOptions();
    final formData = FormData.fromMap({
      'proof_image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });
    final response = await dio.post(
      '/orders/$orderId/upload-proof',
      data: formData,
      options: options,
    );
    return response.data['data']?['proof_url'] ?? '';
  }
}

