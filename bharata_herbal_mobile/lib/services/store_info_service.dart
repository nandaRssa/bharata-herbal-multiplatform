import 'base_service.dart';

/// Store configuration fetched from admin settings via public API.
/// Call this once at app startup (e.g. in SplashScreen) and cache result.
class StoreInfo {
  final String name;
  final String description;
  final String address;
  final String whatsapp;
  final String email;
  final String instagram;

  final int flatRateCost;
  final int freeShippingMin;
  final int minimumOrder;
  final int estimatedDays;

  final List<String> activeMethods;
  final int codFee;
  final List<Map<String, dynamic>> bankAccounts;

  const StoreInfo({
    required this.name,
    required this.description,
    required this.address,
    required this.whatsapp,
    required this.email,
    required this.instagram,
    required this.flatRateCost,
    required this.freeShippingMin,
    required this.minimumOrder,
    required this.estimatedDays,
    required this.activeMethods,
    required this.codFee,
    required this.bankAccounts,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    final store    = json['store']    as Map<String, dynamic>? ?? {};
    final shipping = json['shipping'] as Map<String, dynamic>? ?? {};
    final payment  = json['payment']  as Map<String, dynamic>? ?? {};

    return StoreInfo(
      name:           store['name']        ?? 'Bharata Herbal',
      description:    store['description'] ?? '',
      address:        store['address']     ?? '',
      whatsapp:       store['whatsapp']    ?? '',
      email:          store['email']       ?? '',
      instagram:      store['instagram']   ?? '',
      flatRateCost:   shipping['flat_rate_cost']    ?? 0,
      freeShippingMin:shipping['free_shipping_min'] ?? 0,
      minimumOrder:   shipping['minimum_order']     ?? 0,
      estimatedDays:  shipping['estimated_days']    ?? 3,
      activeMethods:  List<String>.from(payment['active_methods'] ?? []),
      codFee:         payment['cod_fee']   ?? 0,
      bankAccounts:   (payment['bank_accounts'] as List<dynamic>? ?? [])
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList(),
    );
  }
}

class StoreInfoService extends BaseService {
  /// Fetch live store configuration from admin settings.
  /// Returns null on failure (use cached/default values instead).
  Future<StoreInfo?> getStoreInfo() async {
    try {
      final response = await dio.get('/store-info');
      if (response.data['success'] == true) {
        return StoreInfo.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
