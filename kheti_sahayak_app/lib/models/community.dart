class Community {
  final int id;
  final String name;
  final String? description;
  final String? region;
  final int memberCount;
  final String? imageUrl;
  final bool isJoined;

  Community({
    required this.id,
    required this.name,
    this.description,
    this.region,
    this.memberCount = 0,
    this.imageUrl,
    this.isJoined = false,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      region: json['region'],
      memberCount: json['member_count'] ?? 0,
      imageUrl: json['image_url'],
      isJoined: json['is_joined'] == true || json['is_joined'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'region': region,
      'member_count': memberCount,
      'image_url': imageUrl,
      'is_joined': isJoined,
    };
  }
}
