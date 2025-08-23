import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path';

import '../../models/task/task_image.dart';
import '../../utils/logger.dart';

class TaskImageService {
  static const int maxImageSizeMB = 10; // 10MB max file size
  static const int maxImageWidth = 4096; // Max image width in pixels
  static const int maxImageHeight = 4096; // Max image height in pixels
  static const int maxImagesPerTask = 5; // Maximum number of images per task
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  /// Request gallery permission
  Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.status;
    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Pick multiple images from gallery
  Future<List<TaskImage>> pickImages({
    int maxImages = 5,
    bool allowMultiple = true,
  }) async {
    try {
      // Check and request permission
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) {
        throw Exception('Gallery permission not granted');
      }

      // Pick images
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: maxImageWidth.toDouble(),
        maxHeight: maxImageHeight.toDouble(),
        imageQuality: 85,
      );

      // Limit the number of images
      final limitedFiles = pickedFiles.take(maxImages).toList();
      
      // Convert to TaskImage list
      final List<TaskImage> taskImages = [];
      
      for (final file in limitedFiles) {
        try {
          final taskImage = await _processImageFile(file);
          taskImages.add(taskImage);
        } catch (e) {
          AppLogger.error('Error processing image: ${file.path}', e);
          // Continue with other images even if one fails
        }
      }

      return taskImages;
    } catch (e) {
      AppLogger.error('Error picking images', e);
      rethrow;
    }
  }

  /// Process and validate an image file
  Future<TaskImage> _processImageFile(XFile xFile) async {
    // Convert XFile to File
    final file = File(xFile.path);
    
    // Check file size
    final fileSize = await file.length();
    if (fileSize > maxImageSizeMB * 1024 * 1024) {
      throw Exception('Image size exceeds maximum allowed size of ${maxImageSizeMB}MB');
    }

    // Validate image format
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) {
      throw Exception('Invalid image format');
    }

    // Validate dimensions
    if (image.width > maxImageWidth || image.height > maxImageHeight) {
      throw Exception('Image dimensions exceed maximum allowed size of ${maxImageWidth}x${maxImageHeight}');
    }

    // Create a thumbnail (optional, can be done later when needed)
    // final thumbnail = await _createThumbnail(file);

    return TaskImage.fromFile(file);
  }

  /// Create a thumbnail from an image file
  Future<File> _createThumbnail(File originalFile, {int width = 200, int height = 200}) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate aspect ratio
      final aspectRatio = image.width / image.height;
      int targetWidth, targetHeight;
      
      if (aspectRatio > 1) {
        // Landscape
        targetWidth = width;
        targetHeight = (width / aspectRatio).round();
      } else {
        // Portrait or square
        targetHeight = height;
        targetWidth = (height * aspectRatio).round();
      }

      // Resize image
      final thumbnail = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
      );

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final thumbnailFile = File('${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 80));
      
      return thumbnailFile;
    } catch (e) {
      AppLogger.error('Error creating thumbnail', e);
      rethrow;
    }
  }

  /// Compress an image file to reduce size
  Future<File> compressImage(File file, {int quality = 85}) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Get the file extension
      final ext = path.extension(file.path).toLowerCase();
      
      // Encode the image with the specified quality
      List<int> compressedBytes;
      if (ext == '.png') {
        compressedBytes = img.encodePng(image, level: (100 - quality) ~/ 10);
      } else if (ext == '.jpg' || ext == '.jpeg') {
        compressedBytes = img.encodeJpg(image, quality: quality);
      } else {
        // For other formats, just return the original
        return file;
      }

      // Save to a temporary file
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}$ext');
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      AppLogger.error('Error compressing image', e);
      // Return original file if compression fails
      return file;
    }
  }
}
