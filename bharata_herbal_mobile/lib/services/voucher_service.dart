import 'dart:io';
import 'package:dio/dio.dart';
import 'base_service.dart';

class VoucherResult {
  final int voucherId;
  final String code;
  final String name;
  final String discountLabel;
  final int discountAmount;
  final int minPurchase;

  const VoucherResult({
    required this.voucherId,
    required this.code,
    required this.name,
    required this.discountLabel,
    required this.discountAmount,
    required this.minPurchase,
  });

  factory VoucherResult.fromJson(Map<String, dynamic> j) => VoucherResult(
    voucherId:      j['voucher_id'] ?? 0,
    code:           j['code'] ?? '',
    name:           j['name'] ?? '',
    discountLabel:  j['discount_label'] ?? '',
    discountAmount: j['discount_amount'] ?? 0,
    minPurchase:    j['min_purchase'] ?? 0,
  );
}

class VoucherService extends BaseService {
  /// Validate voucher code against current subtotal.
  /// Returns [VoucherResult] on success, throws error message string on failure.
  Future<VoucherResult> validateVoucher({
    required String code,
    required double subtotal,
  }) async {
    final options = await authOptions();
    final response = await dio.post(
      '/vouchers/validate',
      data: {'code': code.toUpperCase().trim(), 'subtotal': subtotal},
      options: options,
    );
    if (response.data['success'] == true) {
      return VoucherResult.fromJson(response.data['data']);
    }
    throw response.data['message'] ?? 'Voucher tidak valid.';
  }

  /// Upload payment proof image for an order.
  Future<String> uploadProof({
    required int orderId,
    required File imageFile,
  }) async {
    final options = await authOptions();
    final formData = FormData.fromMap({
      'proof_image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });
    final response = await dio.post(
      '/orders/$orderId/upload-proof',
      data: formData,
      options: options,
    );
    return response.data['data']['proof_url'] ?? '';
  }

  /// Customer confirms they received the order.
  Future<bool> confirmReceived(int orderId) async {
    final options = await authOptions();
    final response = await dio.post(
      '/orders/$orderId/confirm-received',
      options: options,
    );
    return response.data['success'] == true;
  }
}
