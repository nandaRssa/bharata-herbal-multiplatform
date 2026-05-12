import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';

class AddressProvider with ChangeNotifier {
  final AddressService _service = AddressService();

  List<Address> _addresses = [];
  List<Address> get addresses => _addresses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadAddresses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _addresses = await _service.getAddresses();
    } catch (e) {
      debugPrint('Address load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addAddress(Map<String, dynamic> data) async {
    try {
      final address = await _service.addAddress(data);
      _addresses.add(address);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add address error: $e');
      return false;
    }
  }

  Future<bool> updateAddress(int id, Map<String, dynamic> data) async {
    try {
      final address = await _service.updateAddress(id, data);
      final index = _addresses.indexWhere((a) => a.id == id);
      if (index != -1) {
        _addresses[index] = address;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Update address error: $e');
      return false;
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      await _service.deleteAddress(id);
      _addresses.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete address error: $e');
    }
  }

  Future<void> setDefault(int id) async {
    try {
      await _service.setDefault(id);
      await loadAddresses();
    } catch (e) {
      debugPrint('Set default error: $e');
    }
  }

  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }
}
