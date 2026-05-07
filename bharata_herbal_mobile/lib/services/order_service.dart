import 'base_service.dart';
import '../models/order_model.dart';

class OrderService extends BaseService {
  Future<List<Order>> getOrders({String? status, int page = 1}) async {
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
    final data = response.data['data']['data'] as List<dynamic>? ?? [];
    return data.map((o) => Order.fromJson(o)).toList();
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
    final response = await dio.post(
      '/orders/$orderId/pay',
      options: options,
    );
    return response.data['data'] ?? {};
  }

  Future<bool> buyAgain(int orderId) async {
    final options = await authOptions();
    final response = await dio.post(
      '/orders/$orderId/buy-again',
      options: options,
    );
    return response.data['success'] == true;
  }

  Future<bool> submitReview(
    int orderId,
    int productId,
    int rating,
    String comment,
  ) async {
    final options = await authOptions();
    final response = await dio.post(
      '/orders/$orderId/reviews',
      data: {
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      },
      options: options,
    );
    return response.data['success'] == true;
  }
}
