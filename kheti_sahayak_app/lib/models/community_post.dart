class CommunityPost {
  final int? id; // Server ID
  final int? localId; // Local ID
  final int communityId;
  final String userName;
  final String? userImage;
  final String content;
  final String? imageUrl;
  final String? localImagePath;
  final int likes;
  final int commentsCount;
  final DateTime timestamp;
  
  // Sync fields
  final bool synced;
  final bool dirty;

  CommunityPost({
    this.id,
    this.localId,
    required this.communityId,
    required this.userName,
    this.userImage,
    required this.content,
    this.imageUrl,
    this.localImagePath,
    this.likes = 0,
    this.commentsCount = 0,
    required this.timestamp,
    this.synced = true,
    this.dirty = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      communityId: json['community_id'] ?? 0, // Default to 0 if missing
      userName: json['user_name'],
      userImage: json['user_image'],
      content: json['content'],
      imageUrl: json['image_url'],
      likes: json['likes'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      synced: true,
    );
  }

  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      id: map['backend_id'],
      localId: map['local_id'],
      communityId: map['community_id'],
      userName: map['user_name'],
      userImage: map['user_image'],
      content: map['content'],
      imageUrl: map['image_url'],
      localImagePath: map['local_image_path'],
      likes: map['likes'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
      synced: map['synced'] == 1,
      dirty: map['dirty'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'user_name': userName,
      'user_image': userImage,
      'content': content,
      'image_url': imageUrl,
      'likes': likes,
      'comments_count': commentsCount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'backend_id': id,
      'community_id': communityId,
      'user_name': userName,
      'user_image': userImage,
      'content': content,
      'image_url': imageUrl,
      'local_image_path': localImagePath,
      'likes': likes,
      'comments_count': commentsCount,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced ? 1 : 0,
      'dirty': dirty ? 1 : 0,
    };
  }
}
