class EquipmentListing {
  final int id;
  final String name;
  final String description;
  final String category;
  final double dailyRate;
  final String? imageUrl;
  final String ownerName;
  final String status;

  EquipmentListing({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.dailyRate,
    this.imageUrl,
    required this.ownerName,
    required this.status,
  });

  factory EquipmentListing.fromJson(Map<String, dynamic> json) {
    return EquipmentListing(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
      ownerName: json['owner_name'] ?? 'Unknown',
      status: json['status'],
    );
  }
}
