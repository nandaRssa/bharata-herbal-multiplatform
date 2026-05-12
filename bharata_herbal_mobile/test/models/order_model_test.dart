import 'package:flutter_test/flutter_test.dart';
import 'package:bharata_herbal_mobile/models/order_model.dart';
import 'package:bharata_herbal_mobile/models/address_model.dart';

void main() {
  group('OrderItem.fromJson', () {
    test('parses order item correctly', () {
      final json = {
        'id': 1,
        'product_id': 5,
        'product_name': 'Jamu Kunyit',
        'product_image': 'kunyit.jpg',
        'quantity': 2,
        'unit_price': '25000',
        'subtotal': '50000',
      };

      final item = OrderItem.fromJson(json);

      expect(item.id, 1);
      expect(item.productId, 5);
      expect(item.productName, 'Jamu Kunyit');
      expect(item.quantity, 2);
      expect(item.unitPrice, 25000);
      expect(item.subtotal, 50000);
    });
  });

  group('OrderPayment.fromJson', () {
    test('parses payment correctly', () {
      final json = {
        'id': 1,
        'method': 'bank_transfer',
        'status': 'paid',
        'amount': '65000',
        'paid_at': '2026-05-01 10:00:00',
      };

      final payment = OrderPayment.fromJson(json);

      expect(payment.id, 1);
      expect(payment.methodLabel, 'Transfer Bank');
      expect(payment.statusLabel, 'Pembayaran Terkonfirmasi');
      expect(payment.amount, 65000);
    });

    test('uses custom labels when provided', () {
      final json = {
        'id': 1,
        'method': 'cod',
        'status': 'verified',
        'method_label': 'Bayar di Tempat',
        'status_label': 'Terverifikasi',
        'amount': '50000',
      };

      final payment = OrderPayment.fromJson(json);
      expect(payment.methodLabel, 'Bayar di Tempat');
      expect(payment.statusLabel, 'Terverifikasi');
    });
  });

  group('Order.fromJson', () {
    final baseJson = {
      'id': 1,
      'order_number': 'INV-001',
      'status': 'pending',
      'subtotal': '50000',
      'shipping_cost': '10000',
      'total_price': '60000',
      'is_cod': false,
      'items': [
        {'id': 1, 'product_id': 5, 'product_name': 'Jamu Kunyit', 'quantity': 2, 'unit_price': '25000', 'subtotal': '50000'},
      ],
      'address': {
        'id': 1, 'label': 'Rumah', 'recipient_name': 'Budi', 'phone': '081234567890',
        'street': 'Jl. Test', 'city': 'Jakarta', 'province': 'DKI Jakarta',
        'postal_code': '12345', 'full_address': 'Jl. Test, Jakarta', 'is_default': true,
      },
      'payment': {
        'id': 1, 'method': 'bank_transfer', 'status': 'pending', 'amount': '60000',
      },
      'can_review': false,
      'can_cancel': true,
      'needs_payment': true,
      'can_pay_now': true,
      'can_upload_payment_proof': false,
      'can_confirm_received': false,
      'created_at': '2026-05-01T10:00:00Z',
      'updated_at': '2026-05-01T10:00:00Z',
    };

    test('parses order correctly', () {
      final order = Order.fromJson(baseJson);

      expect(order.id, 1);
      expect(order.orderNumber, 'INV-001');
      expect(order.status, 'pending');
      expect(order.statusLabel, 'Menunggu');
      expect(order.statusColor, 0xFFF59E0B);
      expect(order.statusIcon, '⏳');
      expect(order.subtotal, 50000);
      expect(order.shippingCost, 10000);
      expect(order.totalPrice, 60000);
      expect(order.items.length, 1);
      expect(order.address, isNotNull);
      expect(order.payment, isNotNull);
      expect(order.needsPayment, true);
      expect(order.canPayNow, true);
      expect(order.canBeCancelled, true);
    });

    test('computes status helper getters correctly', () {
      final pending = Order.fromJson({...baseJson, 'status': 'pending'});
      expect(pending.isCompleted, false);
      expect(pending.isCancelled, false);

      final completed = Order.fromJson({...baseJson, 'status': 'completed'});
      expect(completed.isCompleted, true);
      expect(completed.isCancelled, false);

      final cancelled = Order.fromJson({...baseJson, 'status': 'cancelled'});
      expect(cancelled.isCancelled, true);
      expect(cancelled.isCompleted, false);
    });

    test('generates status timeline for non-COD order', () {
      final order = Order.fromJson({...baseJson, 'status': 'paid'});
      final timeline = order.statusTimeline;

      expect(timeline.length, 5);
      expect(timeline[0].status, 'pending');
      expect(timeline[0].isCompleted, true);
      expect(timeline[1].status, 'paid');
      expect(timeline[1].isCurrent, true);
      expect(timeline[4].status, 'completed');
      expect(timeline[4].isCompleted, false);
    });

    test('generates shorter timeline for COD order', () {
      final order = Order.fromJson({...baseJson, 'status': 'pending', 'is_cod': true});
      final timeline = order.statusTimeline;

      expect(timeline.length, 4);
      expect(timeline[0].status, 'pending');
      expect(timeline[1].status, 'processing');
    });
  });
}
