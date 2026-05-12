import 'package:flutter_test/flutter_test.dart';
import 'package:bharata_herbal_mobile/models/cart_model.dart';

void main() {
  group('CartItem.fromJson', () {
    test('parses cart item correctly', () {
      final json = {
        'id': 1,
        'product_id': 5,
        'product_name': 'Jamu Kunyit',
        'product_image': 'kunyit.jpg',
        'quantity': 2,
        'unit_price': '25000',
        'subtotal': '50000',
        'is_selected': true,
      };

      final item = CartItem.fromJson(json);

      expect(item.id, 1);
      expect(item.productId, 5);
      expect(item.productName, 'Jamu Kunyit');
      expect(item.quantity, 2);
      expect(item.unitPrice, 25000);
      expect(item.subtotal, 50000);
      expect(item.isSelected, true);
    });

    test('defaults quantity to 1 when missing', () {
      final json = {'id': 1, 'product_id': 1};
      final item = CartItem.fromJson(json);
      expect(item.quantity, 1);
      expect(item.isSelected, true);
    });
  });

  group('Cart.fromJson', () {
    test('parses cart with items', () {
      final json = {
        'id': 1,
        'items': [
          {'id': 1, 'product_id': 5, 'product_name': 'Jamu Kunyit', 'quantity': 2, 'unit_price': '25000', 'subtotal': '50000'},
          {'id': 2, 'product_id': 6, 'product_name': 'Beras Kencur', 'quantity': 1, 'unit_price': '15000', 'subtotal': '15000'},
        ],
        'total': '65000',
        'selected_count': 2,
        'total_items': 2,
        'minimum_order_amount': '0',
        'is_minimum_met': true,
      };

      final cart = Cart.fromJson(json);

      expect(cart.id, 1);
      expect(cart.items.length, 2);
      expect(cart.total, 65000);
      expect(cart.selectedCount, 2);
      expect(cart.isMinimumMet, true);
      expect(cart.items.first.productName, 'Jamu Kunyit');
    });

    test('handles empty items list', () {
      final json = {'id': 1, 'items': []};
      final cart = Cart.fromJson(json);
      expect(cart.items, isEmpty);
      expect(cart.total, 0);
    });
  });
}
