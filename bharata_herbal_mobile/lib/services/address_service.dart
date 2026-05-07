import 'base_service.dart';
import '../models/address_model.dart';

class AddressService extends BaseService {
  Future<List<Address>> getAddresses() async {
    final options = await authOptions();
    final response = await dio.get('/addresses', options: options);
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((a) => Address.fromJson(a)).toList();
  }

  Future<Address> addAddress(Map<String, dynamic> data) async {
    final options = await authOptions();
    final response = await dio.post('/addresses', data: data, options: options);
    return Address.fromJson(response.data['data']);
  }

  Future<void> deleteAddress(int id) async {
    final options = await authOptions();
    await dio.delete('/addresses/$id', options: options);
  }

  Future<void> setDefault(int id) async {
    final options = await authOptions();
    await dio.patch('/addresses/$id/default', options: options);
  }
}
