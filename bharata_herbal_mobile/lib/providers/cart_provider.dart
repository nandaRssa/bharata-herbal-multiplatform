import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _service = CartService();

  Cart? _cart;
  Cart? get cart => _cart;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int get itemCount => _cart?.totalItems ?? 0;

  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cart = await _service.getCart();
    } catch (e) {
      _errorMessage = 'Gagal memuat keranjang';
      debugPrint('Cart load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> addToCart(int productId, int quantity) async {
    try {
      _cart = await _service.addToCart(productId, quantity);
      notifyListeners();
      return null; // sukses
    } catch (e) {
      final msg = _extractDioError(e);
      return msg;
    }
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    try {
      _cart = await _service.updateQuantity(cartItemId, quantity);
      notifyListeners();
    } catch (e) {
      debugPrint('Update qty error: $e');
    }
  }

  Future<void> removeItem(int cartItemId) async {
    try {
      _cart = await _service.removeItem(cartItemId);
      notifyListeners();
    } catch (e) {
      debugPrint('Remove error: $e');
    }
  }

  Future<void> toggleSelect(int cartItemId) async {
    try {
      _cart = await _service.toggleSelect(cartItemId);
      notifyListeners();
    } catch (e) {
      debugPrint('Toggle select error: $e');
    }
  }

  Future<void> toggleSelectAll(bool selectAll) async {
    try {
      _cart = await _service.toggleSelectAll(selectAll);
      notifyListeners();
    } catch (e) {
      debugPrint('Toggle all error: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      await _service.clearCart();
      _cart = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Clear cart error: $e');
    }
  }

  void clearLocal() {
    _cart = null;
    notifyListeners();
  }

  String _extractDioError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data != null && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
