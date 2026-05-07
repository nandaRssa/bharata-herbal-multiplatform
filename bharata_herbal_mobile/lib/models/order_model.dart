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
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
    );
  }
}

class OrderPayment {
  final int id;
  final String method;
  final String status;
  final double amount;
  final String? proofImageUrl;
  final String? paidAt;

  OrderPayment({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    this.proofImageUrl,
    this.paidAt,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] ?? 0,
      method: json['method'] ?? '',
      status: json['status'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      proofImageUrl: json['proof_image_url'],
      paidAt: json['paid_at'],
    );
  }

  String get methodLabel {
    const map = {
      'bank_transfer': 'Transfer Bank',
      'cash_on_delivery': 'Bayar di Tempat (COD)',
      'ewallet': 'E-Wallet',
    };
    return map[method] ?? method;
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
  final String? estimatedDeliveryAt;
  final List<OrderItem> items;
  final Address? address;
  final OrderPayment? payment;
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
    this.estimatedDeliveryAt,
    required this.items,
    this.address,
    this.payment,
    required this.canReview,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
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
      estimatedDeliveryAt: json['estimated_delivery_at'],
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      address: json['address'] != null && json['address'] is Map
          ? Address.fromJson(json['address'])
          : null,
      payment: json['payment'] != null && json['payment'] is Map
          ? OrderPayment.fromJson(json['payment'])
          : null,
      canReview: json['can_review'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // ─── Status Metadata ──────────────────────────────────────────────

  String get statusLabel {
    const labels = {
      'pending': 'Menunggu Konfirmasi',
      'unpaid': 'Menunggu Pembayaran',
      'processing': 'Sedang Diproses',
      'shipped': 'Sedang Dikirim',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };
    return labels[status] ?? status;
  }

  /// Warna hex per status
  int get statusColor {
    const colors = {
      'pending': 0xFFF59E0B,    // amber
      'unpaid': 0xFFEF4444,     // red
      'processing': 0xFF3B82F6, // blue
      'shipped': 0xFF8B5CF6,    // purple
      'completed': 0xFF2D5016,  // green
      'cancelled': 0xFF6B7280,  // gray
    };
    return colors[status] ?? 0xFF6B7280;
  }

  /// Icon per status
  String get statusIcon {
    const icons = {
      'pending': '⏳',
      'unpaid': '💳',
      'processing': '⚙️',
      'shipped': '🚚',
      'completed': '✅',
      'cancelled': '❌',
    };
    return icons[status] ?? '📦';
  }

  bool get canBeCancelled =>
      status == 'pending' || status == 'unpaid';

  bool get needsPayment => status == 'unpaid';

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  bool get isShipped => status == 'shipped';

  /// Apakah pembayaran sudah kadaluarsa
  bool get isPaymentExpired {
    if (paymentDeadline == null) return false;
    try {
      return DateTime.parse(paymentDeadline!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Sisa waktu pembayaran
  Duration? get paymentTimeRemaining {
    if (paymentDeadline == null) return null;
    try {
      final deadline = DateTime.parse(paymentDeadline!);
      final remaining = deadline.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (_) {
      return null;
    }
  }

  /// Timeline status (untuk OrderDetailScreen)
  List<OrderStatusStep> get statusTimeline {
    const allSteps = [
      ('unpaid', 'Menunggu Pembayaran'),
      ('pending', 'Menunggu Konfirmasi'),
      ('processing', 'Sedang Diproses'),
      ('shipped', 'Sedang Dikirim'),
      ('completed', 'Pesanan Selesai'),
    ];

    final currentIndex = _statusOrder.indexOf(status);

    return allSteps.map((step) {
      final stepIndex = _statusOrder.indexOf(step.$1);
      return OrderStatusStep(
        status: step.$1,
        label: step.$2,
        isCompleted: stepIndex <= currentIndex && !isCancelled,
        isCurrent: stepIndex == currentIndex && !isCancelled,
      );
    }).toList();
  }

  static const _statusOrder = [
    'unpaid',
    'pending',
    'processing',
    'shipped',
    'completed',
  ];
}

class OrderStatusStep {
  final String status;
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  const OrderStatusStep({
    required this.status,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });
}
