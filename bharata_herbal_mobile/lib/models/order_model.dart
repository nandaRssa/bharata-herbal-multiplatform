import 'package:flutter/material.dart';
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
  final String? serverMethodLabel;
  final String? serverStatusLabel;
  final double amount;
  final String? proofImageUrl;
  final String? paidAt;

  OrderPayment({
    required this.id,
    required this.method,
    required this.status,
    this.serverMethodLabel,
    this.serverStatusLabel,
    required this.amount,
    this.proofImageUrl,
    this.paidAt,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] ?? 0,
      method: json['method'] ?? '',
      status: json['status'] ?? '',
      serverMethodLabel: json['method_label'],
      serverStatusLabel: json['status_label'],
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      proofImageUrl: json['proof_image_url'],
      paidAt: json['paid_at'],
    );
  }

  String get methodLabel {
    if (serverMethodLabel != null && serverMethodLabel!.isNotEmpty) {
      return serverMethodLabel!;
    }

    const map = {
      'bank_transfer': 'Transfer Bank',
      'cod': 'Bayar di Tempat (COD)',
      'dana': 'DANA',
      'gopay': 'GoPay',
      'qris': 'QRIS',
      'ewallet': 'E-Wallet',
    };
    return map[method] ?? method;
  }

  String get statusLabel {
    if (serverStatusLabel != null && serverStatusLabel!.isNotEmpty) {
      return serverStatusLabel!;
    }

    const map = {
      'pending': 'Menunggu Pembayaran',
      'pending_confirmation': 'Menunggu Konfirmasi Admin',
      'verified': 'Pembayaran Terkonfirmasi',
      'paid': 'Dibayar',
      'failed': 'Gagal',
    };

    return map[status] ?? status;
  }

  bool get isWaitingConfirmation => status == 'pending_confirmation';
}

/// Tracking update dari backend
class TrackingUpdate {
  final int id;
  final String keterangan;
  final String lokasi;
  final String? createdAt;

  TrackingUpdate({
    required this.id,
    required this.keterangan,
    required this.lokasi,
    this.createdAt,
  });

  factory TrackingUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingUpdate(
      id: json['id'] ?? 0,
      keterangan: json['keterangan'] ?? '',
      lokasi: json['lokasi'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String? serverStatusLabel;
  final double subtotal;
  final double shippingCost;
  final double totalPrice;
  final double? discountAmount;
  final String? notes;
  final String? trackingNumber;
  final String? courierName;
  final String? courierLabel;
  final String? cancelReason;
  final String? paymentDeadline;
  final String? estimatedDeliveryAt;
  final bool isCod;
  final List<OrderItem> items;
  final Address? address;
  final OrderPayment? payment;
  final bool canReview;
  final List<int> reviewedProductIds;
  final bool canCancel;
  final bool needsPaymentFlag;
  final bool canPayNowFlag;
  final bool canUploadPaymentProofFlag;
  final bool canConfirmReceivedFlag;
  final List<TrackingUpdate> trackingUpdates;
  final String createdAt;
  final String updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.serverStatusLabel,
    required this.subtotal,
    required this.shippingCost,
    required this.totalPrice,
    this.discountAmount,
    this.notes,
    this.trackingNumber,
    this.courierName,
    this.courierLabel,
    this.cancelReason,
    this.paymentDeadline,
    this.estimatedDeliveryAt,
    required this.isCod,
    required this.items,
    this.address,
    this.payment,
    required this.canReview,
    this.reviewedProductIds = const [],
    required this.canCancel,
    required this.needsPaymentFlag,
    required this.canPayNowFlag,
    required this.canUploadPaymentProofFlag,
    required this.canConfirmReceivedFlag,
    this.trackingUpdates = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      serverStatusLabel: json['status_label'],
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      shippingCost: double.tryParse(json['shipping_cost'].toString()) ?? 0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
      discountAmount: json['discount_amount'] != null
          ? double.tryParse(json['discount_amount'].toString())
          : null,
      notes: json['notes'],
      trackingNumber: json['tracking_number'],
      courierName: json['courier_name'],
      courierLabel: json['courier_label'],
      cancelReason: json['cancel_reason'],
      paymentDeadline: json['payment_deadline'],
      estimatedDeliveryAt: json['estimated_delivery_at'],
      isCod: json['is_cod'] ?? false,
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
      reviewedProductIds: (json['reviewed_product_ids'] as List<dynamic>? ?? [])
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .toList(),
      canCancel: json['can_cancel'] ?? false,
      needsPaymentFlag: json['needs_payment'] ?? false,
      canPayNowFlag: json['can_pay_now'] ?? false,
      canUploadPaymentProofFlag: json['can_upload_payment_proof'] ?? false,
      canConfirmReceivedFlag: json['can_confirm_received'] ?? false,
      trackingUpdates: (json['tracking_updates'] as List<dynamic>? ?? [])
          .map((t) => TrackingUpdate.fromJson(t))
          .toList(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // ─── Status Metadata ──────────────────────────────────────────────

  String get statusLabel {
    if (serverStatusLabel != null && serverStatusLabel!.isNotEmpty) {
      return serverStatusLabel!;
    }

    const labels = {
      'pending': 'Menunggu',
      'paid': 'Pembayaran Terkonfirmasi',
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
      'paid': 0xFF2563EB,       // blue
      'processing': 0xFF3B82F6, // blue
      'shipped': 0xFFF97316,    // orange
      'completed': 0xFF1A5C38,  // green
      'cancelled': 0xFF6B7280,  // gray
    };
    return colors[status] ?? 0xFF6B7280;
  }

  /// Icon per status
  IconData get statusIcon {
    const icons = {
      'pending': Icons.hourglass_empty_rounded,
      'paid': Icons.payment_rounded,
      'processing': Icons.replay_rounded,
      'shipped': Icons.local_shipping_rounded,
      'completed': Icons.check_circle_rounded,
      'cancelled': Icons.cancel_rounded,
    };
    return icons[status] ?? Icons.inventory_2_rounded;
  }

  bool get canBeCancelled => canCancel;

  bool get needsPayment => needsPaymentFlag;

  bool get canPayNow => canPayNowFlag;

  bool get canUploadPaymentProof => canUploadPaymentProofFlag;

  bool get canConfirmReceived => canConfirmReceivedFlag;

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  bool get isShipped => status == 'shipped';

  /// Check if a specific product has already been reviewed
  bool isProductReviewed(int productId) => reviewedProductIds.contains(productId);

  /// Whether payment proof is awaiting admin confirmation
  bool get isWaitingConfirmation =>
      payment != null && payment!.isWaitingConfirmation;

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
    final allSteps = isCod
        ? const [
            ('pending', 'Pesanan Masuk'),
            ('processing', 'Sedang Diproses'),
            ('shipped', 'Sedang Dikirim'),
            ('completed', 'Pesanan Selesai'),
          ]
        : const [
            ('pending', 'Menunggu Pembayaran'),
            ('paid', 'Pembayaran Terkonfirmasi'),
            ('processing', 'Sedang Diproses'),
            ('shipped', 'Sedang Dikirim'),
            ('completed', 'Pesanan Selesai'),
          ];

    final statusOrder = allSteps.map((step) => step.$1).toList();
    final currentIndex = statusOrder.indexOf(status);

    return allSteps.map((step) {
      final stepIndex = statusOrder.indexOf(step.$1);
      return OrderStatusStep(
        status: step.$1,
        label: step.$2,
        isCompleted: stepIndex <= currentIndex && !isCancelled,
        isCurrent: stepIndex == currentIndex && !isCancelled,
      );
    }).toList();
  }

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
