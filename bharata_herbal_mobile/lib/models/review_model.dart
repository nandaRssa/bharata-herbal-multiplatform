class Review {
  final int id;
  final String reviewerName;
  final double rating;
  final String? comment;
  final String? imageUrl;
  final String createdAt;

  Review({
    required this.id,
    required this.reviewerName,
    required this.rating,
    this.comment,
    this.imageUrl,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      reviewerName: json['reviewer_name'] ?? json['user_name'] ?? 'Pengguna',
      rating: double.tryParse(json['rating'].toString()) ?? 5.0,
      comment: json['comment'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
