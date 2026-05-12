import 'package:flutter_test/flutter_test.dart';
import 'package:bharata_herbal_mobile/models/address_model.dart';

void main() {
  group('Address.fromJson', () {
    test('parses full address correctly', () {
      final json = {
        'id': 1,
        'label': 'Rumah',
        'recipient_name': 'Budi',
        'phone': '081234567890',
        'street': 'Jl. Merdeka No. 1',
        'city': 'Jakarta Selatan',
        'province': 'DKI Jakarta',
        'postal_code': '12345',
        'full_address': 'Jl. Merdeka No. 1, Jakarta Selatan, DKI Jakarta 12345',
        'is_default': true,
      };

      final address = Address.fromJson(json);

      expect(address.id, 1);
      expect(address.label, 'Rumah');
      expect(address.recipientName, 'Budi');
      expect(address.phone, '081234567890');
      expect(address.street, 'Jl. Merdeka No. 1');
      expect(address.city, 'Jakarta Selatan');
      expect(address.province, 'DKI Jakarta');
      expect(address.postalCode, '12345');
      expect(address.fullAddress, contains('Jl. Merdeka'));
      expect(address.isDefault, true);
    });

    test('defaults to empty values when fields are missing', () {
      final json = {'id': 1};
      final address = Address.fromJson(json);
      expect(address.label, 'Alamat');
      expect(address.recipientName, '');
      expect(address.phone, '');
      expect(address.isDefault, false);
    });
  });
}
