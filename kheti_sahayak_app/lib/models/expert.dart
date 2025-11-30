class Expert {
  final int id;
  final String name;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final double rating;
  final String? imageUrl;
  final bool isOnline;

  Expert({
    required this.id,
    required this.name,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.rating,
    this.imageUrl,
    required this.isOnline,
  });

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      qualification: json['qualification'],
      experienceYears: json['experience_years'],
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['image_url'],
      isOnline: json['is_online'] ?? false,
    );
  }
}
