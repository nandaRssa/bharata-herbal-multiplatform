import 'package:flutter_test/flutter_test.dart';
import 'package:bharata_herbal_mobile/models/product_model.dart';

void main() {
  group('Product.fromJson', () {
    test('parses product correctly', () {
      final json = {
        'id': 1,
        'name': 'Jamu Kunyit',
        'slug': 'jamu-kunyit',
        'description': 'Minuman herbal tradisional',
        'price': '25000',
        'image': 'kunyit.jpg',
        'image_url': 'http://example.com/kunyit.jpg',
        'stock': 10,
        'rating': '4.5',
        'benefits': 'Menyehatkan tubuh',
        'ingredients': 'Kunyit, jahe',
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.name, 'Jamu Kunyit');
      expect(product.slug, 'jamu-kunyit');
      expect(product.price, '25000');
      expect(product.stock, 10);
      expect(product.rating, 4.5);
      expect(product.benefits, 'Menyehatkan tubuh');
    });

    test('defaults missing fields to empty values', () {
      final json = {'id': 1, 'name': 'Test', 'price': '10000'};
      final product = Product.fromJson(json);
      expect(product.slug, '');
      expect(product.description, '');
      expect(product.rating, 0.0);
      expect(product.benefits, null);
    });
  });
}
