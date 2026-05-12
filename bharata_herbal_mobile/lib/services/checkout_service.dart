import 'dart:convert';
import 'package:flutter/material.dart';
import 'base_service.dart';
import '../models/address_model.dart';
import '../models/cart_model.dart';

const _paymentLabels = {
  'cod': ('Bayar di Tempat (COD)', Icons.payments_rounded),
  'bank_transfer': ('Transfer Bank', Icons.account_balance_rounded),
  'dana': ('DANA', Icons.account_balance_wallet_rounded),
  'gopay': ('GoPay', Icons.phone_android_rounded),
  'qris': ('QRIS', Icons.qr_code_rounded),
};

class PaymentOption {
  final String backendValue;
  final String label;
  final IconData icon;

  const PaymentOption({
    required this.backendValue,
    required this.label,
    required this.icon,
  });
}

List<PaymentOption> buildPaymentOptions(List<String> methods) {
  return methods.map((method) {
    final info = _paymentLabels[method] ?? (method.toUpperCase(), Icons.credit_card_rounded);

    return PaymentOption(
      backendValue: method,
      label: info.$1,
      icon: info.$2,
    );
  }).toList();
}

class ShippingCourier {
  final String code;
  final String label;
  final double cost;
  final int estimatedDays;

  const ShippingCourier({
    required this.code,
    required this.label,
    required this.cost,
    required this.estimatedDays,
  });

  factory ShippingCourier.fromJson(Map<String, dynamic> json) {
    return ShippingCourier(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      cost: double.tryParse(json['cost'].toString()) ?? 0,
      estimatedDays: int.tryParse(json['estimated_days'].toString()) ?? 0,
    );
  }
}

class CheckoutSummary {
  final Cart cart;
  final List<Map<String, dynamic>> selectedItems;
  final List<Address> addresses;
  final Address? defaultAddress;
  final List<PaymentOption> paymentOptions;
  final String shippingMethod;
  final List<ShippingCourier> couriers;
  final String? defaultCourierCode;
  final List<Map<String, dynamic>> bankAccounts;
  final double subtotal;
  final double shippingCost;
  final double freeShippingMin;
  final bool isFreeShipping;
  final double codFee;
  final double total;
  final double minimumOrderAmount;
  final bool isMinimumMet;

  CheckoutSummary({
    required this.cart,
    required this.selectedItems,
    required this.addresses,
    this.defaultAddress,
    required this.paymentOptions,
    required this.shippingMethod,
    required this.couriers,
    required this.defaultCourierCode,
    required this.bankAccounts,
    required this.subtotal,
    required this.shippingCost,
    required this.freeShippingMin,
    required this.isFreeShipping,
    required this.codFee,
    required this.total,
    required this.minimumOrderAmount,
    required this.isMinimumMet,
  });

  bool get usesCourierSelection => shippingMethod == 'automatic' && couriers.isNotEmpty;

  ShippingCourier? findCourier(String? code) {
    if (code == null) return null;

    for (final courier in couriers) {
      if (courier.code == code) {
        return courier;
      }
    }

    return null;
  }

  double shippingCostFor(ShippingCourier? courier) {
    if (isFreeShipping) return 0;
    if (usesCourierSelection && courier != null) return courier.cost;
    return shippingCost;
  }

  double totalFor(PaymentOption option, {double discount = 0, ShippingCourier? courier}) {
    final shipping = shippingCostFor(courier);
    final fee = option.backendValue == 'cod' ? codFee : 0;

    return (subtotal + shipping + fee - discount).clamp(0, double.infinity);
  }
}

class CheckoutService extends BaseService {
  Future<CheckoutSummary> getCheckoutSummary() async {
    final options = await authOptions();
    final response = await dio.get('/checkout', options: options);
    final data = response.data['data'];

    final rawMethods = data['payment_methods'];
    List<String> methodKeys;
    if (rawMethods is List) {
      methodKeys = List<String>.from(rawMethods);
    } else if (rawMethods is String) {
      try {
        methodKeys = rawMethods.isNotEmpty
            ? List<String>.from(jsonDecode(rawMethods))
            : <String>[];
      } catch (_) {
        methodKeys = [];
      }
    } else {
      methodKeys = [];
    }

    if (methodKeys.isEmpty) {
      methodKeys = ['bank_transfer', 'cod'];
    }

    final rawCouriers = data['couriers'] as List<dynamic>? ?? [];
    final couriers = rawCouriers
        .map((courier) => ShippingCourier.fromJson(Map<String, dynamic>.from(courier as Map)))
        .toList();

    final rawBanks = data['bank_accounts'] as List<dynamic>? ?? [];
    final bankAccounts = rawBanks
        .map<Map<String, dynamic>>((bank) => Map<String, dynamic>.from(bank as Map))
        .toList();

    return CheckoutSummary(
      cart: Cart.fromJson(data['cart']),
      selectedItems: List<Map<String, dynamic>>.from(data['selected_items'] ?? []),
      addresses: (data['addresses'] as List<dynamic>? ?? [])
          .map((address) => Address.fromJson(address))
          .toList(),
      defaultAddress: data['default_address'] != null
          ? Address.fromJson(data['default_address'])
          : null,
      paymentOptions: buildPaymentOptions(methodKeys),
      shippingMethod: data['shipping_method']?.toString() ?? 'flat_rate',
      couriers: couriers,
      defaultCourierCode: data['default_courier_code']?.toString(),
      bankAccounts: bankAccounts,
      subtotal: double.tryParse(data['subtotal'].toString()) ?? 0,
      shippingCost: double.tryParse(data['shipping_cost'].toString()) ?? 0,
      freeShippingMin: double.tryParse(data['free_shipping_min'].toString()) ?? 0,
      isFreeShipping: data['is_free_shipping'] == true,
      codFee: double.tryParse(data['cod_fee'].toString()) ?? 0,
      total: double.tryParse(data['total'].toString()) ?? 0,
      minimumOrderAmount: double.tryParse(data['minimum_order_amount'].toString()) ?? 0,
      isMinimumMet: data['is_minimum_met'] ?? false,
    );
  }

  Future<Map<String, dynamic>> placeOrder({
    required int addressId,
    required PaymentOption paymentOption,
    String? courierCode,
    String notes = '',
    String? voucherCode,
  }) async {
    final options = await authOptions();
    final response = await dio.post(
      '/checkout',
      data: {
        'address_id': addressId,
        'payment_method': paymentOption.backendValue,
        if (courierCode != null && courierCode.isNotEmpty) 'courier_code': courierCode,
        'notes': notes,
        if (voucherCode != null && voucherCode.isNotEmpty)
          'voucher_code': voucherCode.toUpperCase().trim(),
      },
      options: options,
    );

    return response.data;
  }
}
