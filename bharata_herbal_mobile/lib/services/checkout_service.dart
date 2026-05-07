import 'base_service.dart';
import '../models/address_model.dart';
import '../models/cart_model.dart';

/// Payment method yang ditampilkan di UI (user-friendly)
enum PaymentMethod {
  cod('cash_on_delivery', 'Bayar di Tempat (COD)', '💵'),
  transfer('transfer', 'Transfer Bank', '🏦'),
  ewallet('transfer', 'E-Wallet (GoPay/OVO/Dana)', '📱'); // backend maps to transfer

  final String backendValue; // nilai yang dikirim ke API
  final String label;
  final String emoji;

  const PaymentMethod(this.backendValue, this.label, this.emoji);
}

class CheckoutSummary {
  final Cart cart;
  final List<Map<String, dynamic>> selectedItems;
  final List<Address> addresses;
  final Address? defaultAddress;
  final List<String> paymentMethods;
  final List<Map<String, dynamic>> bankAccounts;
  final double subtotal;
  final double shippingCost;
  final double total;
  final double minimumOrderAmount;
  final bool isMinimumMet;

  CheckoutSummary({
    required this.cart,
    required this.selectedItems,
    required this.addresses,
    this.defaultAddress,
    required this.paymentMethods,
    required this.bankAccounts,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    required this.minimumOrderAmount,
    required this.isMinimumMet,
  });
}

class CheckoutService extends BaseService {
  Future<CheckoutSummary> getCheckoutSummary() async {
    final options = await authOptions();
    final response = await dio.get('/checkout', options: options);
    final d = response.data['data'];

    return CheckoutSummary(
      cart: Cart.fromJson(d['cart']),
      selectedItems: List<Map<String, dynamic>>.from(
        d['selected_items'] ?? [],
      ),
      addresses: (d['addresses'] as List<dynamic>? ?? [])
          .map((a) => Address.fromJson(a))
          .toList(),
      defaultAddress: d['default_address'] != null
          ? Address.fromJson(d['default_address'])
          : null,
      paymentMethods: List<String>.from(d['payment_methods'] ?? []),
      bankAccounts: List<Map<String, dynamic>>.from(d['bank_accounts'] ?? []),
      subtotal: double.tryParse(d['subtotal'].toString()) ?? 0,
      shippingCost: double.tryParse(d['shipping_cost'].toString()) ?? 0,
      total: double.tryParse(d['total'].toString()) ?? 0,
      minimumOrderAmount:
          double.tryParse(d['minimum_order_amount'].toString()) ?? 0,
      isMinimumMet: d['is_minimum_met'] ?? false,
    );
  }

  Future<Map<String, dynamic>> placeOrder({
    required int addressId,
    required PaymentMethod paymentMethod,
    String notes = '',
  }) async {
    final options = await authOptions();
    final response = await dio.post(
      '/checkout',
      data: {
        'address_id': addressId,
        'payment_method': paymentMethod.backendValue, // mapping ke backend value
        'notes': notes,
      },
      options: options,
    );
    return response.data;
  }
}
