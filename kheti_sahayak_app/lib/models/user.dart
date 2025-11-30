class User {
  final String id;
  String username;
  final String email;
  final String? phoneNumber;
  final String? fullName;
  final String? address;
  final String? profileImageUrl;
  final String? bio;
  final String? role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.fullName,
    this.address,
    this.profileImageUrl,
    this.bio,
    this.role = 'user',
    required this.createdAt,
    this.updatedAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle full_name from either full_name field or first_name + last_name
    String? fullName = json['full_name'];
    if (fullName == null && (json['first_name'] != null || json['last_name'] != null)) {
      final firstName = json['first_name'] ?? '';
      final lastName = json['last_name'] ?? '';
      fullName = '$firstName $lastName'.trim();
      if (fullName.isEmpty) fullName = null;
    }

    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'],
      fullName: fullName,
      address: json['address'],
      profileImageUrl: json['profile_image_url'],
      bio: json['bio'],
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      isEmailVerified: json['is_email_verified'] ?? json['is_verified'] ?? false,
      isPhoneVerified: json['is_phone_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (fullName != null) 'full_name': fullName,
      if (address != null) 'address': address,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (bio != null) 'bio': bio,
      if (role != null) 'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
    };
  }

  // Create a copy of the user with updated fields
  User copyWith({
    String? username,
    String? email,
    String? phoneNumber,
    String? fullName,
    String? address,
    String? profileImageUrl,
    String? bio,
    String? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}