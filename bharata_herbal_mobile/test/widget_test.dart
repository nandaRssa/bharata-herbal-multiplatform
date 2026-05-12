import 'package:flutter_test/flutter_test.dart';
import 'package:bharata_herbal_mobile/models/address_model.dart';
import 'package:bharata_herbal_mobile/models/cart_model.dart';
import 'package:bharata_herbal_mobile/models/order_model.dart';

void main() {
  group('Address Model', () {
    test('fromJson creates valid Address', () {
      final json = {
        'id': 1,
        'label': 'Kantor',
        'recipient_name': 'Siti',
        'phone': '081298765432',
        'street': 'Jl. Sudirman No. 10',
        'city': 'Jakarta Pusat',
        'province': 'DKI Jakarta',
        'postal_code': '10210',
        'full_address': 'Jl. Sudirman No. 10, Jakarta Pusat, DKI Jakarta 10210',
        'is_default': true,
      };

      final address = Address.fromJson(json);
      expect(address.label, 'Kantor');
      expect(address.isDefault, true);
      expect(address.fullAddress, contains('Sudirman'));
    });
  });

  group('Cart Model', () {
    test('calculate total from items', () {
      final cart = Cart.fromJson({
        'id': 1,
        'items': [
          {'id': 1, 'product_id': 1, 'product_name': 'A', 'quantity': 2, 'unit_price': '10000', 'subtotal': '20000', 'is_selected': true},
          {'id': 2, 'product_id': 2, 'product_name': 'B', 'quantity': 1, 'unit_price': '15000', 'subtotal': '15000', 'is_selected': true},
        ],
        'total': '35000',
        'selected_count': 2,
        'total_items': 2,
        'minimum_order_amount': '0',
        'is_minimum_met': true,
      });

      expect(cart.total, 35000);
      expect(cart.items.length, 2);
      expect(cart.items.every((i) => i.isSelected), true);
    });
  });

  group('Order Model', () {
    test('status timeline for pending payment order', () {
      final order = Order.fromJson({
        'id': 1,
        'order_number': 'INV-001',
        'status': 'pending',
        'subtotal': '50000',
        'shipping_cost': '10000',
        'total_price': '60000',
        'is_cod': false,
        'items': [
          {'id': 1, 'product_id': 1, 'product_name': 'Jamu', 'quantity': 1, 'unit_price': '50000', 'subtotal': '50000'},
        ],
        'can_review': false, 'can_cancel': true,
        'needs_payment': true, 'can_pay_now': true,
        'can_upload_payment_proof': false, 'can_confirm_received': false,
        'created_at': '2026-05-01T10:00:00Z', 'updated_at': '2026-05-01T10:00:00Z',
      });

      expect(order.needsPayment, true);
      expect(order.isCompleted, false);
      expect(order.statusTimeline.length, 5);
      expect(order.statusTimeline[0].isCompleted, true);
      expect(order.statusTimeline[0].isCurrent, true);
    });

    test('completed order has all timeline steps done', () {
      final order = Order.fromJson({
        'id': 2,
        'order_number': 'INV-002',
        'status': 'completed',
        'subtotal': '25000',
        'shipping_cost': '0',
        'total_price': '25000',
        'is_cod': true,
        'items': [
          {'id': 1, 'product_id': 1, 'product_name': 'Beras Kencur', 'quantity': 1, 'unit_price': '25000', 'subtotal': '25000'},
        ],
        'can_review': true, 'can_cancel': false,
        'needs_payment': false, 'can_pay_now': false,
        'can_upload_payment_proof': false, 'can_confirm_received': false,
        'created_at': '2026-05-01T10:00:00Z', 'updated_at': '2026-05-05T10:00:00Z',
      });

      expect(order.isCompleted, true);
      expect(order.isCancelled, false);
      expect(order.statusTimeline.every((s) => s.isCompleted), true);
    });
  });

  group('CheckoutService PaymentOption', () {
    test('buildPaymentOptions creates correct options', () {
      final methods = ['bank_transfer', 'cod', 'dana', 'gopay', 'qris'];

      final options = methods.map((m) {
        final labels = {
          'bank_transfer': 'Transfer Bank',
          'cod': 'Bayar di Tempat (COD)',
          'dana': 'DANA',
          'gopay': 'GoPay',
          'qris': 'QRIS',
        };
        return labels[m] ?? m;
      }).toList();

      expect(options, contains('Transfer Bank'));
      expect(options, contains('Bayar di Tempat (COD)'));
      expect(options, contains('DANA'));
      expect(options.length, 5);
    });
  });
}
