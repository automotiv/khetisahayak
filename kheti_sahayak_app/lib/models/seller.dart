class Seller {
  final String id;
  final String name;
  final String businessName;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String? imageUrl;
  final String? location;

  Seller({
    required this.id,
    required this.name,
    required this.businessName,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.imageUrl,
    this.location,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'],
      name: json['name'],
      businessName: json['business_name'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      imageUrl: json['image_url'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'business_name': businessName,
      'rating': rating,
      'review_count': reviewCount,
      'is_verified': isVerified,
      'image_url': imageUrl,
      'location': location,
    };
  }
}
