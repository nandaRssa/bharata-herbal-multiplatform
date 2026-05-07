import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service = OrderService();

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  Order? _selectedOrder;
  Order? get selectedOrder => _selectedOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _statusFilter = '';
  String get statusFilter => _statusFilter;

  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    if (status != null) _statusFilter = status;
    notifyListeners();
    try {
      _orders = await _service.getOrders(
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );
    } catch (e) {
      _error = 'Gagal memuat pesanan';
      debugPrint('Orders error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOrderDetail(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedOrder = await _service.getOrderDetail(orderId);
    } catch (e) {
      _error = 'Gagal memuat detail pesanan';
      debugPrint('Order detail error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      final ok = await _service.cancelOrder(orderId, reason);
      if (ok) await loadOrders();
      return ok;
    } catch (e) {
      debugPrint('Cancel order error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> payNow(int orderId) async {
    try {
      return await _service.payNow(orderId);
    } catch (e) {
      debugPrint('Pay now error: $e');
      return {};
    }
  }

  Future<bool> buyAgain(int orderId) async {
    try {
      return await _service.buyAgain(orderId);
    } catch (e) {
      debugPrint('Buy again error: $e');
      return false;
    }
  }

  Future<bool> submitReview(
    int orderId,
    int productId,
    int rating,
    String comment,
  ) async {
    try {
      final ok = await _service.submitReview(orderId, productId, rating, comment);
      if (ok) await loadOrderDetail(orderId);
      return ok;
    } catch (e) {
      debugPrint('Submit review error: $e');
      return false;
    }
  }
}
