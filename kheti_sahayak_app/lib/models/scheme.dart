class Scheme {
  final int id;
  final String name;
  final String description;
  final String? benefits;
  final String? eligibility;
  final String? category;
  final String? link;

  Scheme({
    required this.id,
    required this.name,
    required this.description,
    this.benefits,
    this.eligibility,
    this.category,
    this.link,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      benefits: json['benefits'],
      eligibility: json['eligibility'],
      category: json['category'],
      link: json['link'],
    );
  }
}
