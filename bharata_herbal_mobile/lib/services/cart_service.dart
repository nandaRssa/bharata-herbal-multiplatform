import 'base_service.dart';
import '../models/cart_model.dart';

class CartService extends BaseService {
  Future<Cart> getCart() async {
    final options = await authOptions();
    final response = await dio.get('/cart', options: options);
    return Cart.fromJson(response.data['data']);
  }

  Future<Cart> addToCart(int productId, int quantity) async {
    final options = await authOptions();
    final response = await dio.post(
      '/cart',
      data: {'product_id': productId, 'quantity': quantity},
      options: options,
    );
    return Cart.fromJson(response.data['data']);
  }

  Future<Cart> updateQuantity(int cartItemId, int quantity) async {
    final options = await authOptions();
    final response = await dio.patch(
      '/cart/$cartItemId',
      data: {'quantity': quantity},
      options: options,
    );
    return Cart.fromJson(response.data['data']);
  }

  Future<Cart> removeItem(int cartItemId) async {
    final options = await authOptions();
    final response = await dio.delete('/cart/$cartItemId', options: options);
    return Cart.fromJson(response.data['data']);
  }

  Future<Cart> toggleSelect(int cartItemId) async {
    final options = await authOptions();
    final response = await dio.patch(
      '/cart/$cartItemId/toggle-select',
      options: options,
    );
    return Cart.fromJson(response.data['data']);
  }

  Future<Cart> toggleSelectAll(bool selectAll) async {
    final options = await authOptions();
    final response = await dio.post(
      '/cart/toggle-select-all',
      data: {'select_all': selectAll},
      options: options,
    );
    return Cart.fromJson(response.data['data']);
  }

  Future<void> clearCart() async {
    final options = await authOptions();
    await dio.delete('/cart', options: options);
  }
}
