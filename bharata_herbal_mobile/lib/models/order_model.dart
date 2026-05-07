import 'address_model.dart';

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double shippingCost;
  final double totalPrice;
  final String? notes;
  final String? trackingNumber;
  final String? courierName;
  final String? cancelReason;
  final String? paymentDeadline;
  final List<OrderItem> items;
  final Address? address;
  final bool canReview;
  final String createdAt;
  final String updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.shippingCost,
    required this.totalPrice,
    this.notes,
    this.trackingNumber,
    this.courierName,
    this.cancelReason,
    this.paymentDeadline,
    required this.items,
    this.address,
    required this.canReview,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      shippingCost: double.tryParse(json['shipping_cost'].toString()) ?? 0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
      notes: json['notes'],
      trackingNumber: json['tracking_number'],
      courierName: json['courier_name'],
      cancelReason: json['cancel_reason'],
      paymentDeadline: json['payment_deadline'],
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      address:
          json['address'] != null ? Address.fromJson(json['address']) : null,
      canReview: json['can_review'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String get statusLabel {
    const labels = {
      'pending': 'Menunggu',
      'unpaid': 'Belum Bayar',
      'processing': 'Diproses',
      'shipped': 'Dikirim',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };
    return labels[status] ?? status;
  }
}
