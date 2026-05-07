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
  final String? benefits;
  final String? ingredients;

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
    this.benefits,
    this.ingredients,
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
      benefits: json['benefits'],
      ingredients: json['ingredients'],
    );
  }
}
