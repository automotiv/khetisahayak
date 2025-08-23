import 'dart:io';

class TaskImage {
  final String? id;
  final String? url; // For images from the server
  final File? file; // For newly selected images
  final String? thumbnailUrl; // For thumbnails from the server
  final String? name;
  final int? size;
  final DateTime? uploadedAt;
  final String? mimeType;

  TaskImage({
    this.id,
    this.url,
    this.file,
    this.thumbnailUrl,
    this.name,
    this.size,
    this.uploadedAt,
    this.mimeType,
  }) : assert(url != null || file != null, 'Either url or file must be provided');

  bool get isLocal => file != null;
  bool get isRemote => url != null;

  String get displayName => name ?? file?.path.split('/').last ?? '';

  // Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name ?? file?.path.split('/').last,
      'size': size ?? file?.lengthSync(),
      'mimeType': mimeType,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }

  // Create from JSON (from API)
  factory TaskImage.fromJson(Map<String, dynamic> json) {
    return TaskImage(
      id: json['id'],
      url: json['url'],
      thumbnailUrl: json['thumbnailUrl'],
      name: json['name'],
      size: json['size'],
      mimeType: json['mimeType'],
      uploadedAt: json['uploadedAt'] != null ? DateTime.parse(json['uploadedAt']) : null,
    );
  }

  // Create from file (for new selections)
  factory TaskImage.fromFile(File file) {
    return TaskImage(
      file: file,
      name: file.path.split('/').last,
      size: file.lengthSync(),
      mimeType: _getMimeType(file.path),
    );
  }

  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
