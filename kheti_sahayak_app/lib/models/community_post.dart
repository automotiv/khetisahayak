class CommunityPost {
  final int id;
  final String userName;
  final String? userImage;
  final String content;
  final String? imageUrl;
  final int likes;
  final int commentsCount;
  final DateTime timestamp;

  CommunityPost({
    required this.id,
    required this.userName,
    this.userImage,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.commentsCount,
    required this.timestamp,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      userName: json['user_name'],
      userImage: json['user_image'],
      content: json['content'],
      imageUrl: json['image_url'],
      likes: json['likes'],
      commentsCount: json['comments_count'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
