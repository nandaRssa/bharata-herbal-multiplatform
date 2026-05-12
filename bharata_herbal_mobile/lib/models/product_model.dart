import 'review_model.dart';

class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String price;
  final String image;
  final String imageUrl;
  final int stock;
  final double rating;
  final int ratingCount;
  final String? benefits;
  final String? ingredients;
  final List<Review> reviews;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.image,
    required this.imageUrl,
    required this.stock,
    required this.rating,
    required this.ratingCount,
    this.benefits,
    this.ingredients,
    this.reviews = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      price: json['price'].toString(),
      image: json['image'] ?? '',
      imageUrl: json['image_url'] ?? '',
      stock: json['stock'] ?? 0,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
      benefits: json['benefits'],
      ingredients: json['ingredients'] ?? json['composition'],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List).map((v) => Review.fromJson(v)).toList()
          : [],
    );
  }
}
